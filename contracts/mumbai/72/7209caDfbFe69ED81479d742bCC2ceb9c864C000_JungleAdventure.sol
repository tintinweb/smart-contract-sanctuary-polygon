pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "IERC20.sol";
import "SafeMath.sol";
import "IERC721.sol";
import "IERC1155.sol";
import "Ownable.sol";
import "JungleLogic.sol";
import "VRFConsumerBase2Mumbai.sol";
import "KongzExtraData.sol";


interface ILock is IERC721 {
	function lockId(uint256 _id) external;
	function unlockId(uint256 _id) external;
}

interface INana is IERC20 {
	function burn(uint256 _amount) external;
}

contract JungleAdventure is VRFConsumerBaseV2Mumbai {
	using SafeMath for uint256;

	struct CharmEffect {
		uint256 charmType;
		uint256 hp;
	}

	struct AdventureData {
		address user;
		uint256 data;
	}

	address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
	bytes32 constant public KONGIUM_ID = 0x6b446311b91ce49327a43ee3d0f0361dbfae79e9b9af3f89d0d8420676a1abb0;
	bytes32 constant public LVL_ID = 0xd7fe74ba2795604f471717a6182ac81070ad95ecee0b7d8ebcfbec785af7e796;

	bool setup;
	bool public isPaused;
	INana public nanas;
	ILock public vx;
	IERC1155 public charms;
	IJungleLogic public logic;
	KongzExtraData public extraData;
	bool public useVrf;
	uint256 counter;

	// 10 days 8 hours
	uint256 public seasonDuration = 892800;
	uint256 public season;

	uint256 public nanaFee;
	uint256 public energyFee;
	uint256 public rodCost = 500;
	uint256 public nanaCost = 200;
	uint256[4] public nanaRewardTable;

	mapping(address => mapping(uint256 => uint256)) public teams;
	mapping(address => uint256) public teamCount;
	mapping(address => uint256) public weights;

	mapping(address => mapping(uint256 => CharmEffect)) public charmInUse;

	// add + 1 always
	mapping(uint256 => uint256) public vxXp;
	mapping(uint256 => uint256) public lastFreeRun;
	
	mapping(uint256 => mapping(address => uint256)) public energyCount;
	mapping(uint256 => mapping(address => uint256)) public seasonLastUpdate;
	mapping(uint256 => uint256) public seasonStartTime;
	mapping(uint256 => uint256) public seasonRewardBalance;

	mapping(uint256 => mapping(address => uint256)) public committedKongium;
	mapping(uint256 => uint256) public globalCommittedKongium;
	mapping(address => mapping(uint256 => bool)) public hasCommitted;

	mapping(address => bool) public approvedContract;
	mapping(uint256 => AdventureData) adventureData;

	event StartSeason(uint256 id, uint256 prize);
	event TeamAdded(address owner, uint256 teamId, uint256 teamData);
	event TeamChanged(address owner, uint256 teamId, uint256 teamData);
	event TeamRemoved(address owner, uint256 teamId);
	event ActivateCharm(uint256 teamId, uint256 charm);
	event CommitKongium(uint256 indexed seasonId, uint256 amount, address indexed commiter);
	event UpgradeVX(uint256[] tokenIds, uint256[] newLevels);
	event KongiumBurn(address indexed user, uint256 amount);
	event KongiumMint(address indexed user, uint256 amount);
	event AdventureDone(address indexed user, uint256 indexed teamId, uint256 data, uint256 timestamp);

	constructor(address _nanas, address _vx, address _charms, address _logic, address _extra,address _vrfCoordinator, address _link) public VRFConsumerBaseV2Mumbai(_vrfCoordinator, _link) {
		nanas = INana(_nanas);
		energyFee = 1e6;
		vx = ILock(_vx);
		charms = IERC1155(_charms);
		logic = IJungleLogic(_logic);
		extraData = KongzExtraData(_extra);
		nanaRewardTable[0] = 5000 ether;
		nanaRewardTable[1] = 10000 ether;
		nanaRewardTable[2] = 15000 ether;
		nanaRewardTable[3] = 20000 ether;
	}

	function init(address _nanas, address _vx, address _charms, address _logic, address _extra,address _vrfCoordinator, address _link, address _newOwner) external {
		require(!setup);
		setup = true;

		nanas = INana(_nanas);
		energyFee = 1e6;
		vx = ILock(_vx);
		charms = IERC1155(_charms);
		logic = IJungleLogic(_logic);
		extraData = KongzExtraData(_extra);
		nanaRewardTable[0] = 5000 ether;
		nanaRewardTable[1] = 10000 ether;
		nanaRewardTable[2] = 15000 ether;
		nanaRewardTable[3] = 20000 ether;
		_initVRF(_vrfCoordinator, _link);
		_owner = _newOwner;
        emit OwnershipTransferred(address(0), _newOwner);
	}

	function setPause(bool _val) external onlyOwner {
		isPaused = _val;
	}

	function startSeason() external onlyOwner {
		_startSeason();
	}

	function updateSeasonLength(uint256 _length) external onlyOwner {
		seasonDuration = _length;
	}

	function switchVrf(bool _val) external onlyOwner {
		useVrf = _val;
	}

	function updateApprovedContracts(address[] calldata _contracts, bool[] calldata _values) external onlyOwner {
		require(_contracts.length == _values.length, "!length");
		for(uint256 i = 0; i < _contracts.length; i++)
			approvedContract[_contracts[i]] = _values[i];
	}

	function updateLogic(address _logic) external onlyOwner {
		logic = IJungleLogic(_logic);
	}

	function updateExtraData(address _extra) external onlyOwner {
		extraData = KongzExtraData(_extra);
	}

	function updateNanaFee(uint256 _fee) external onlyOwner {
		nanaFee = _fee;
	}

	function updateRodCost(uint256 _cost) external onlyOwner {
		rodCost = _cost;
	}
	
	function updateNanaCost(uint256 _cost) external onlyOwner {
		nanaCost = _cost;
	}

	function updateEnergyFee(uint256 _fee) external onlyOwner {
		energyFee = _fee;
	}

	function burnKongium(address _user, uint256 _amount) external {
		require(approvedContract[msg.sender], "JungleAdventure: Not allowed to burn kongium");
		_spendKongium(_user, _amount);
	}

	function mintKongium(address _user, uint256 _amount) public {
		require(approvedContract[msg.sender], "JungleAdventure: Not allowed to mint kongium");
		_mintKongium(_user, _amount);
	}

	function grantExp(uint256 _tokenId, uint256 _amount) public {
		require(approvedContract[msg.sender], "JungleAdventure: Not allowed to mint kongium");
		vxXp[_tokenId] = vxXp[_tokenId].add(_amount);
	}

	/*=================* User accessed functions *=================*/
	function addTeam(uint256[5] calldata _vx) external {
		uint256 team = 0;
		uint256 count = teamCount[msg.sender];
		uint256 weight = 0;
		for(uint256 i = 0; i < _vx.length; i++) {
			if (_vx[i] != 0) {
				require(vx.ownerOf(_vx[i]) == msg.sender, "!owner");
				weight++;
				vx.lockId(_vx[i]);
			}
			team = (team + _vx[i]) << 32;
		}
		team >>= 32;
		require(team > 0, "KongAdventures: Empty team");
		_syncEnergy(msg.sender);
		weights[msg.sender] += weight;
		teams[msg.sender][count] = team;
		teamCount[msg.sender]++;
		emit TeamAdded(msg.sender, count, team);
	}

	function removeTeam(uint256 _id) external {
		uint256 team = teams[msg.sender][_id];
		require(team != 0, "KongAdventures: Empty team");
		uint256 count = teamCount[msg.sender];
		uint256 weight = 0;

		for (uint256 i = 0 ; i < 5; i ++) {
			uint256 vxId = (team >> (32 * i)) & 0xffffffff;
			if (vxId != 0) {
				weight++;
				vx.unlockId(vxId);
			}
		}
		if (count > 1) {
			teams[msg.sender][_id] = teams[msg.sender][count - 1];
			charmInUse[msg.sender][_id] = charmInUse[msg.sender][count - 1];
		}
		teams[msg.sender][count - 1] = 0;
		delete charmInUse[msg.sender][count - 1];
		_syncEnergy(msg.sender);
		weights[msg.sender] -= weight;
		teamCount[msg.sender]--;
		emit TeamRemoved(msg.sender, _id);
	}

	function editTeam(uint256 _id, uint256[5] calldata _vx) external {
		uint256 team = teams[msg.sender][_id];
		require(team != 0, "KongAdventures: Empty team");
		uint256 currentTeamWeight = _vxInTeam(team);
		uint256 newTeam;
		uint256 weight;
		for (uint256 i = 0 ; i < 5; i++) {
			uint256 vxId = (team >> (32 * (4 - i))) & 0xffffffff;
			uint256 newId = _vx[i];
			if (newId > 0 && newId != vxId) {
				require(vx.ownerOf(newId) == msg.sender, "!owner");
				vx.lockId(newId);
			}
			if (vxId > 0 && newId != vxId)
				vx.unlockId(vxId);
			newTeam = (newTeam + newId) << 32;
			if (newId > 0)
				weight++;		
		}
		newTeam >>= 32;
		require(newTeam != 0, "KongAdventures: Empty team");
		teams[msg.sender][_id] = newTeam;
		_syncEnergy(msg.sender);
		if (weight > currentTeamWeight)
			weights[msg.sender] += weight - currentTeamWeight;
		else if (weight < currentTeamWeight)
			weights[msg.sender] -= currentTeamWeight - weight;
		emit TeamChanged(msg.sender, _id, newTeam);
	}

	function activateCharm(uint256 _teamId, uint256 _charm) external {
		require(_teamId < teamCount[msg.sender], "JungleAdventure: Index does not exist");
		charmInUse[msg.sender][_teamId] = CharmEffect(_charm, 10001);
		charms.safeTransferFrom(msg.sender, BURN_ADDRESS, _charm, 1, "");
		emit ActivateCharm(_teamId, _charm);
	}

	function upgradeVxLvl(uint256[] calldata _vx) external {
		uint256 expReq;
		uint256 kongiumReq;
		uint256[] memory newLevels = new uint256[](_vx.length);
		for (uint256 i = 0 ; i < _vx.length; i++) {
			require(vx.ownerOf(_vx[i]) == msg.sender, "!owner");
			uint256 lvl = extraData.stats(_vx[i], LVL_ID);
			(expReq, kongiumReq) = logic.getReqForLvl(lvl + 1);
			_spendExp(_vx[i], expReq);
			_spendKongium(msg.sender, kongiumReq);
			extraData.incStats(LVL_ID, _vx[i], 1);
			newLevels[i] = lvl + 1;
		}
		emit UpgradeVX(_vx, newLevels);
	}

	function kongium(address _user) external view returns(uint256) {
		return extraData.items(_user, KONGIUM_ID);
	}

	function getLevelsInTeam(uint256 _team) public view returns(uint256[5] memory _levels) {
		for (uint256 i = 0; i < 5; i++) {
			uint256 vxId = (_team >> (32 * i)) & 0xffffffff;
			if (vxId > 0)
				_levels[i] = extraData.stats(vxId, LVL_ID) + 1;
			else
				_levels[i] = 0;
		}
	}

	function getCharmInUse(address _user, uint256 _index) external view returns(uint256) {
		CharmEffect memory charm = charmInUse[_user][_index];
		if (charm.hp > 0)
			return charm.charmType;
		return 0;
	}

	function getKongStats(uint256[] calldata _kongIds) public view returns(uint256[] memory, uint256[] memory, uint256[] memory) {
		uint256[] memory _levels = new uint256[](_kongIds.length);
		uint256[] memory exp = new uint256[](_kongIds.length);
		uint256[] memory lastFreeRuns = new uint256[](_kongIds.length);
        for (uint256 i = 0; i < _kongIds.length; i++) {
                exp[i] = vxXp[_kongIds[i]];
                _levels[i] = extraData.stats(_kongIds[i], LVL_ID) + 1;
				lastFreeRuns[i] = lastFreeRun[_kongIds[i]];
        }
		return (_levels, exp, lastFreeRuns);
    }

	function getExpInTeam(uint256 _team) public view returns(uint256[5] memory exp) {
		for (uint256 i = 0; i < 5; i++) {
			uint256 vxId = (_team >> (32 * i)) & 0xffffffff;
			if (vxId > 0)
				exp[i] = vxXp[vxId];
			else
				exp[i] = 0;
		}
	}

	function pendingEnergy(address _user) external view returns(uint256) {
		uint startTime = seasonStartTime[season];
		uint256 time = min(block.timestamp - startTime, seasonDuration);
		uint256 timerUser = seasonLastUpdate[season][_user];
		return weights[_user].mul(1e6).mul(time.sub(timerUser)).div(86400);
	}

	function runAdventure(uint256 _teamId, bool _energy) external {
		require(!useVrf, "Use VRF");
		require(!isPaused, "!paused");
		uint256 team = teams[msg.sender][_teamId];
		require(team > 0, "JungleAdventure: team not set");

		_syncEnergy(msg.sender);
		uint256 bonusExp;
		if (_energy)
			_spendEnergy(msg.sender, _vxInTeam(team) * energyFee);
		else {
			uint256 fee = _vxInTeam(team).mul(nanaFee);
			nanas.transferFrom(msg.sender, address(this), fee);
			seasonRewardBalance[season] = seasonRewardBalance[season].add(fee.div(2));
			nanas.transfer(owner(), fee.div(10));
			nanas.transfer(BURN_ADDRESS, fee.sub(fee.div(2)).sub(fee.div(10)));
			bonusExp++;
		}
		_consumeCharm(msg.sender, _teamId, _energy);
		(uint256 gameData, 
		 address[2] memory rewardAddress,
		 uint256[2] memory tokenId,
		 uint256[2] memory amounts,
		 uint256[2] memory tokenTypes) = logic.run(_getActiveCharm(msg.sender, _teamId), _generateSeed(0), team, getLevelsInTeam(team));
		uint256 expFlag = _increaseXp(team, (((gameData >> 32) & 0xffffffff) + bonusExp) * (1 + ((gameData >> 224) & 1)));
		for (uint256 i = 0; i < 2; i++) {
			if (tokenTypes[i] == 1155) {
				IERC1155(rewardAddress[i]).safeTransferFrom(address(this), msg.sender, tokenId[i], amounts[i], "");
			}
			else if (tokenTypes[i] == 20) {
				IERC20(rewardAddress[i]).transfer(msg.sender, amounts[i]);
			}
		}
		_mintKongium(msg.sender, gameData & 0xffffffff);
		emit AdventureDone(
			msg.sender,
			team,
			gameData |
			(expFlag << 64) |
			(bonusExp << 69) |
			(_encodeTeam(getLevelsInTeam(team)) << 70) |
			(_getActiveCharm(msg.sender, _teamId) << 95),
			block.timestamp);
	}

	function runAdventureVRF(uint256 _teamId, bool _energy) external returns(uint256) {
		require(useVrf, "Don't use VRF");
		require(!isPaused, "!paused");
		uint256 team = teams[msg.sender][_teamId];
		require(team > 0, "JungleAdventure: team not set");
		_syncEnergy(msg.sender);
		uint256 bonusExp;
		if (_energy)
			_spendEnergy(msg.sender, _vxInTeam(team) * energyFee);
		else {
			uint256 fee = _vxInTeam(team).mul(nanaFee);
			nanas.transferFrom(msg.sender, address(this), fee);
			seasonRewardBalance[season] = seasonRewardBalance[season].add(fee.div(2));
			nanas.transfer(owner(), fee.div(10));
			nanas.transfer(BURN_ADDRESS, fee.sub(fee.div(2)).sub(fee.div(10)));
			bonusExp++;
		}
		uint256 requestId = requestRandomWords();
		_consumeCharm(msg.sender, _teamId, _energy);
		adventureData[requestId] = AdventureData({
			user: msg.sender,
			data: _encodeGameData(bonusExp, _getActiveCharm(msg.sender, _teamId), team, getLevelsInTeam(team))
		});
		return requestId;
	}

	function commitKongium() external {
		require(block.timestamp < seasonDuration + seasonStartTime[season], "Committing is over");
		require(!isPaused, "!paused");

		uint256 amount = extraData.items(msg.sender, KONGIUM_ID);
		committedKongium[season][msg.sender] += amount;
		globalCommittedKongium[season] += amount;
		_spendKongium(msg.sender, amount);
		emit CommitKongium(season, amount, msg.sender);
	}
	
	function claimNana(uint256 _season) external {
		require(_season < season, "future");
		// require(block.timestamp > seasonDuration + seasonStartTime[_season], "Committing is not over");

		uint256 committedCount = committedKongium[_season][msg.sender];
		uint256 globalCount = globalCommittedKongium[_season];
		uint256 amountToGive = seasonRewardBalance[_season].mul(committedCount).div(globalCount);
		committedKongium[_season][msg.sender] = 0;
		globalCommittedKongium[_season] = globalCount.sub(committedCount);
		seasonRewardBalance[_season] = seasonRewardBalance[_season].sub(amountToGive);
		nanas.transfer(msg.sender, amountToGive);
	}

	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
		AdventureData memory userData = adventureData[requestId];
		address user = userData.user;
		uint256 data = userData.data;
		(uint256 gameData,
		 address[2] memory rewardAddress,
		 uint256[2] memory tokenId,
		 uint256[2] memory amounts,
		 uint256[2] memory tokenTypes) = logic.run((data >> 185) & 3, _generateSeed(randomWords[0]), data & (2 ** 160 - 1), _decodeTeamLevels((data >> 160) & 33554431));
		uint256 expFlag = _increaseXp(data & (2 ** 160 - 1), (((gameData >> 32) & 0xffffffff) + (data >> 187)) * (1 + ((gameData >> 224) & 1)));
		for (uint256 i = 0; i < 2; i++) {
			if (tokenTypes[i] == 1155) {
				IERC1155(rewardAddress[i]).safeTransferFrom(address(this), user, tokenId[i], amounts[i], "");
			}
			else if (tokenTypes[i] == 20) {
				IERC20(rewardAddress[i]).transfer(user, amounts[i]);
			}
		}
		_mintKongium(user, gameData & 0xffffffff);
		emit AdventureDone(
			user,
			data & (2 ** 160 - 1),
			gameData |
			(expFlag << 64) |
			((data >> 187) << 69) |
			(((data >> 160) & 33554431) << 70) |
			(((data >> 185) & 3) << 95),
			block.timestamp);
	}

	function _encodeGameData(uint256 _bonusExp, uint256 _charm, uint256 _team, uint256[5] memory _levels) internal pure returns(uint256) {
		uint256 data = _bonusExp << 2;
		data += _charm;
		data <<= 25;
		data += _encodeTeam(_levels);
		data <<= 160;
		data += _team;
		return data;
	}

	function _encodeTeam(uint256[5] memory _levels) internal pure returns(uint256) {
		uint256 teamData;
		for (uint256 i = 0 ; i < _levels.length; i++) {
			teamData = (teamData + _levels[i]) << 5;
		}
		teamData >>= 5;
		return teamData;
	}

	function _decodeTeamLevels(uint256 _levelsData) internal pure returns(uint256[5] memory teamLevels) {
		for (uint256 i = 0 ; i < 5; i++) {
			teamLevels[4 - i] = (_levelsData >> (5 * i)) & 31;
		}
	}

	function _startSeason() internal {
		seasonStartTime[++season] = block.timestamp;
		uint256 seed = _generateSeed(0);
		uint256 prize = nanaRewardTable[seed % 4];
		_fundSeason(prize);
		emit StartSeason(season, prize);
	}

	function _fundSeason(uint256 _amount) internal {
		seasonRewardBalance[season] += _amount;
		nanas.transferFrom(owner(), address(this), _amount);
	}

	function _getActiveCharm(address _user, uint256 _teamId) internal view returns(uint256) {
		CharmEffect memory charm = charmInUse[_user][_teamId];
		if (charm.hp > 0)
			return charm.charmType;
		return 0;
	}

	function _consumeCharm(address _user, uint256 _teamId, bool _energy) internal {
		CharmEffect storage charm = charmInUse[_user][_teamId];
		uint256 hp = charm.hp;
		uint256 cost;
		if (hp > 0) {
			if (_energy)
				cost = rodCost;
			else
				cost = nanaCost;
			charm.hp = hp < cost ? 0 : (hp - cost);
		}
	}

	function _vxInTeam(uint256 _team) internal pure returns(uint256) {
		uint _teamCount = 0;
		for (uint256 i = 0; i < 5; i++) {
			uint256 vxId = (_team >> (32 * i)) & 0xffffffff;
			_teamCount += vxId > 0 ? 1 : 0;
		}
		return _teamCount;
	}

	function _generateSeed(uint256 _seed) internal returns(uint256 rand) {
		if (_seed == 0)
			rand = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, counter++)));
		else
			rand = uint256(keccak256(abi.encodePacked(_seed)));
	}

	function _canClaimFreeExp(uint256 _vx, uint256 _now) internal returns(uint256) {
		uint256 lastUpdate = lastFreeRun[_vx];
		if (lastUpdate == 0) {
			lastFreeRun[_vx] = _now;
			return 1;
		}
		else if (_now.sub(lastUpdate) > 86400) {
			lastFreeRun[_vx] += 86400 * (_now.sub(lastUpdate).div(86400));
			return 1;
		}
		return 0;
	}

	function _increaseXp(uint256 _team, uint256 _value) internal returns(uint256 expFlag) {
		uint256 _now = block.timestamp;
		for (uint256 i = 0; i < 5; i++) {
			uint256 vxId = (_team >> (32 * i)) & 0xffffffff;
			if (vxId > 0 ) {
				uint freeExp = _canClaimFreeExp(vxId, _now);
				if (freeExp > 0)
					expFlag |= 1 << i;
				vxXp[vxId] += _value + freeExp;
			}
		}
	}

	function _spendEnergy(address _user, uint256 _amount) internal {
		energyCount[season][_user] = energyCount[season][_user].sub(_amount, "!energy");
	}

	function _spendKongium(address _user, uint256 _amount) internal {
		extraData.decItem(KONGIUM_ID, _user, _amount);
	}

	function _mintKongium(address _user, uint256 _amount) internal {
		extraData.incItem(KONGIUM_ID, _user, _amount);
	}

	function _spendExp(uint256 _vx, uint256 _amount) internal {
		vxXp[_vx] = vxXp[_vx].sub(_amount, "!exp");
	}

	function _checkSeason() internal {
		if (block.timestamp > seasonStartTime[season] + seasonDuration)
			_startSeason();
	}

	function _syncEnergy(address _user) internal {
		require(season > 0, "Game not started");
		if (!isPaused)
			_checkSeason();
		uint startTime = seasonStartTime[season];
		uint256 time = min(block.timestamp - startTime, seasonDuration);
		uint256 timerUser = seasonLastUpdate[season][_user];
		// weight * (time - timerUSer) / 86400
		if (time > timerUser)
			energyCount[season][_user] += weights[_user].mul(1e6).mul(time.sub(timerUser)).div(86400);
		seasonLastUpdate[season][_user] = time;
	}

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4) {
		return JungleAdventure.onERC1155Received.selector;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.12;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "IERC20.sol";
import "SafeMath.sol";
import "IERC721.sol";
import "IERC1155.sol";
import "Ownable.sol";

interface IJungleLogic {
	function run(uint256 _charm, uint256 _seed, uint256 _team, uint256[5] calldata _levels )
		external
		view
		returns(uint256 gameData, address[2] memory rewardAddress, uint256[2] memory tokenId, uint256[2] memory amounts, uint256[2] memory tokenTypes);
	function getReqForLvl(uint256 _currentLevel) external view returns(uint256 exp, uint256 kongium);
}

contract JungleLogic is IJungleLogic, Ownable {

	// struct GameEvent {
	// 	uint256 eventType; // 2 bits
	// 	uint256 charmRequirement; // 2 bits
	// 	uint256 teamSizeRequirement; // 3 bits
	// 	uint256 singleLevelRequirement; // 5 bits
	// 	uint256 totalLevelRequirement; // 7 bits
	// 	uint256 tokenType; // 11 bits
	// 	uint256 chance; // 17 bits
	// 	address tokenReward; // 160 bits
	// 	uint256 reward; // 128 bits
	// 	uint256 amount; // 128 bits
	// }

	struct GameEvent {
		uint256 l1;
		uint256 l2;
	}

	uint256 constant MAX_CHANCE = 100000;
	uint256 public eventCounter;
	uint256 public enabledEventCounter;
	uint256 public maxChanceCounter;
	mapping(uint256 => GameEvent) public gameEvents;
	mapping(uint256 => uint256) public gameEventQueue;

	uint256 public charmEventCounter;
	uint256 public enabledCharmEventCounter;
	uint256 public charmMaxChanceCounter;
	mapping(uint256 => GameEvent) public charmGameEvents;
	mapping(uint256 => uint256) public charmGameEventQueue;

	function addEvent(
		uint256 _chance,
		uint256 _eventType,
		uint256 _tokenType,
		address _token,
		uint256 _reward,
		uint256  _amount,
		uint256 _singleLevel,
		uint256 _totalLevel,
		uint256 _teamSize,
		uint256 _charm) external onlyOwner {
		require(_chance <= MAX_CHANCE);
		uint256 l1 = _eventType << 2;
		l1 = (l1 + _charm) << 3;
		l1 = (l1 + _teamSize) << 5;
		l1 = (l1 + _singleLevel) << 7;
		l1 = (l1 + _totalLevel) << 11;
		l1 = (l1 + _tokenType) << 17;
		l1 = (l1 + _chance) << 160;
		l1 = l1 + uint256(uint160(_token));
		uint l2 = (_reward << 128) + _amount;
		gameEvents[eventCounter++] = GameEvent(l1, l2);
	}

	function enableEvent(uint256 _eventId) external onlyOwner {
		require(_eventId < eventCounter, "Outside of range");
		GameEvent memory _event = gameEvents[_eventId];
		require(maxChanceCounter + _chance(_event.l1) <= MAX_CHANCE, "chance");
		gameEventQueue[enabledEventCounter++] = _eventId;
		maxChanceCounter += _chance(_event.l1);
	}

	function disableEvent(uint256 _index) external onlyOwner {
		require(_index < enabledEventCounter, "Outside of range");
		uint256 eventId = gameEventQueue[_index];
		GameEvent memory _event = gameEvents[eventId];
		gameEventQueue[_index] = gameEventQueue[enabledEventCounter - 1];
		delete gameEventQueue[enabledEventCounter - 1];
		enabledEventCounter--;
		maxChanceCounter -= _chance(_event.l1);
	}

	function charmAddEvent(
		uint256 _chance,
		uint256 _eventType,
		uint256 _tokenType,
		address _token,
		uint256 _reward,
		uint256  _amount,
		uint256 _singleLevel,
		uint256 _totalLevel,
		uint256 _teamSize,
		uint256 _charm) external onlyOwner {
		require(_chance <= MAX_CHANCE);
		require(_charm > 0, "!charm");
		uint256 l1 = _eventType << 2;
		l1 = (l1 + _charm) << 3;
		l1 = (l1 + _teamSize) << 5;
		l1 = (l1 + _singleLevel) << 7;
		l1 = (l1 + _totalLevel) << 11;
		l1 = (l1 + _tokenType) << 17;
		l1 = (l1 + _chance) << 160;
		l1 = l1 + uint256(uint160(_token));
		uint l2 = (_reward << 128) + _amount;
		charmGameEvents[charmEventCounter++] = GameEvent(l1, l2);
	}

	function charmDisableEvent(uint256 _index) external onlyOwner {
		require(_index < enabledCharmEventCounter, "Outside of range");
		uint256 charmEventId = charmGameEventQueue[_index];
		GameEvent memory _event = charmGameEvents[charmEventId];
		gameEventQueue[_index] = charmGameEventQueue[enabledCharmEventCounter - 1];
		delete charmGameEventQueue[enabledCharmEventCounter - 1];
		enabledCharmEventCounter--;
		charmMaxChanceCounter -= _chance(_event.l1);
	}

	function charmEnableEvent(uint256 _eventId) external onlyOwner {
		require(_eventId < charmEventCounter, "Outside of range");
		GameEvent storage _event = charmGameEvents[_eventId];
		require(charmMaxChanceCounter + _chance(_event.l1) <= MAX_CHANCE);
		charmGameEventQueue[enabledCharmEventCounter++] = _eventId;
		charmMaxChanceCounter += _chance(_event.l1);
	}

	function _getRange(uint256 _level) internal pure returns(uint256 min, uint256 max) {
		if (_level == 1) {
			min = 1;
			max = 5;
		}
		else if (_level == 2) {
			min = 1;
			max = 6;
		}
		else if (_level == 3) {
			min = 1;
			max = 7;
		}
		else if (_level == 4) {
			min = 1;
			max = 8;
		}
		else if (_level == 5) {
			min = 1;
			max = 9;
		}
		else if (_level == 6) {
			min = 1;
			max = 10;
		}
		else if (_level == 7) {
			min = 2;
			max = 10;
		}
		else if (_level == 8) {
			min = 3;
			max = 10;
		}
		else if (_level == 9) {
			min = 4;
			max = 10;
		}
		else if (_level == 10) {
			min = 5;
			max = 10;
		}
		else if (_level == 11) {
			min = 5;
			max = 11;
		}
		else if (_level == 12) {
			min = 5;
			max = 12;
		}
		else if (_level == 13) {
			min = 5;
			max = 13;
		}
		else if (_level == 14) {
			min = 5;
			max = 14;
		}
		else if (_level == 15) {
			min = 5;
			max = 15;
		}
		else if (_level == 16) {
			min = 6;
			max = 15;
		}
		else if (_level == 17) {
			min = 7;
			max = 15;
		}
		else if (_level == 18) {
			min = 8;
			max = 15;
		}
		else if (_level == 19) {
			min = 9;
			max = 15;
		}
		else if (_level == 20) {
			min = 10;
			max = 15;
		}	
	}

	function _rollDoubleKongium(uint256 _seed, uint256 _charm) internal pure returns(bool) {
		uint256 rand = _seed % 100;
		if (_charm == 1 && rand < 20)
			return true;
		else if (_charm == 2 && rand < 40)
			return true;
		else if (_charm == 3 && rand < 100)
			return true;
		return false;
	}

	function _rollDoubleExp(uint256 _seed, uint256 _charm) internal pure returns(uint256) {
		uint256 rand = _seed % 100;
		if (_charm == 1 && rand < 10)
			return 2;
		else if (_charm == 2 && rand < 20)
			return 2;
		else if (_charm == 3 && rand < 50)
			return 2;
		return 1;
	}

	function _rollRandomEvent(uint256 _seed, uint256 _team, uint256[5] calldata _levels, uint256 _charm) internal view returns(uint256, uint256) {
		_seed = _seed % MAX_CHANCE;
		uint256 len = enabledEventCounter;
		uint256 counter;
		uint256 eventData;

		for (uint256 i = 0; i < len; i++) {
			uint256 eventId = gameEventQueue[i];
			uint256 l1 = gameEvents[eventId].l1;
			counter += _chance(l1);
			if (_seed < counter) {
				eventData = ((eventId + 1) << 4) + (_eventType(l1) << 2);
				if (_totalLevel(l1) <= _sumOfLevels(_levels) &&
					_singleLevel(l1) <= _maxLevel(_levels) &&
					_teamSize(l1)<= _vxInTeam(_team) &&
					_charmRequirement(l1)<= _charm)
					return (eventId + 1, eventData + 2);
				else
					return (0, eventData);
			}
		}
		return (0, 0);
	}

	function _rollRandomCharmEvent(uint256 _seed, uint256 _team, uint256[5] calldata _levels, uint256 _charm) internal view returns(uint256, uint256) {
		_seed= _seed % MAX_CHANCE;
		uint256 len = enabledCharmEventCounter;
		uint256 counter;
		uint256 eventData;

		for (uint256 i = 0; i < len; i++) {
			uint256 eventId = charmGameEventQueue[i];
			uint256 l1 = charmGameEvents[eventId].l1;
			counter += _chance(l1);
			if (_seed < counter) {
				eventData = ((eventId + 1) << 4) + (_eventType(l1) << 2);
				if (_totalLevel(l1) <= _sumOfLevels(_levels) &&
					_singleLevel(l1) <= _maxLevel(_levels) &&
					_teamSize(l1)<= _vxInTeam(_team) &&
					_charmRequirement(l1)<= _charm)
					return (eventId + 1, eventData + 2);
				else
					return (0, eventData);
			}
		}
		return (0, 0);
	}

	// starting from left
	// gameData: 1-30 -> kongium earned per vx | 31 : double kongium | 32 : double exp
	//           33-40 : charm event id - 1 (0 is no event) 41-42: event type |  43: if eligible | 44: if succeeded (applicable for event type 3))
	//           45-76: event ID data (exp/kongium/exp+kongium)
	// 			 77-88: repeat with bit 84 for success of type 3
	// 			 89-120 : event Id data
	// 
	// starting from right
	// 			1-32 : kongium earned | 33-64: bonusExp
	function run(uint256 _charm, uint256 _seed, uint256 _team, uint256[5] calldata _levels)
		external
		view
		override
		returns(uint256 gameData, address[2] memory rewardAddress, uint256[2] memory tokenId, uint256[2] memory amounts, uint256[2] memory tokenTypes) {
		uint256 counter;
		{
			uint256 min;
			uint256 max;
			for (uint256 i = 0; i < _levels.length; i++) {
				if (_levels[i] > 0) {
					(min, max) = _getRange(_levels[i]);
					counter += min + _seed % (max - min);
					gameData = gameData + min + _seed % (max - min);
					_seed = generateSeed(_seed);
				}
				gameData <<= 6;
			}
		}
		gameData >>= 5;
		_seed = generateSeed(_seed);
		if (_rollDoubleKongium(_seed, _charm)) {
			gameData++;
			counter *= 2;
		}
		gameData <<= 1;
		_seed = generateSeed(_seed);
		if (_rollDoubleExp(_seed, _charm) == 2)
			gameData++;
		_seed = generateSeed(_seed);
		{
			uint256 l1;
			uint256 l2;
			gameData <<= 12;
			if (_charm > 0) {
				(l1, l2) = _rollRandomCharmEvent(_seed, _team, _levels, _charm);
				gameData = (gameData + l2) << 32;
				if (l1 > 0) {
					GameEvent memory _event = charmGameEvents[l1 - 1];
					l1 = _event.l1;
					l2 = _event.l2;
					// extra kongium
					if (_eventType(l1) == 0) {
						gameData += _reward(l2);
						counter += _reward(l2);
					}
					// extra exp
					else if (_eventType(l1) == 1) {
						gameData += _reward(l2);
						counter += _reward(l2) << 32;
					}
					// extra exp and kongium
					else if (_eventType(l1) == 2) {
						gameData += ((_reward(l2) & (2 ** 64 - 1)) << 16) + ((_reward(l2) >> 64));
						counter += _reward(l2) & (2 ** 64 - 1);
						counter += (_reward(l2) >> 64) << 32;
					}
					// nft
					else if (_eventType(l1) == 3) {
						if (_tokenType(l1) == 1155) {
							if (IERC1155(_token(l1)).balanceOf(msg.sender, _reward(l2)) > _amount(l2)) {
								gameData |= (1 << 32);
								rewardAddress[0] = _token(l1);
								tokenId[0] = _reward(l2);
								amounts[0] = _amount(l2);
								tokenTypes[0] = 1155;
							}
							else
								counter += 500;
						}
						else if (_tokenType(l1) == 20) {
							if (IERC20(_token(l1)).balanceOf(msg.sender) > _amount(l2)) {
								gameData |= (1 << 32);
								rewardAddress[0] = _token(l1);
								amounts[0] = _amount(l2);
								tokenTypes[0] = 20;
							}
							else
								counter += 500;
						}
					}
				}
			}
			else
				gameData <<= 32;
			_seed = generateSeed(_seed);
			gameData <<= 12;
			(l1, l2) = _rollRandomEvent(_seed, _team, _levels, _charm);
			gameData = (gameData + l2) << 32;
			if (l1 > 0) {
				GameEvent memory _event = gameEvents[l1 - 1];
				l1 = _event.l1;
				l2 = _event.l2;
				// extra kongium
				if (_eventType(l1) == 0) {
					gameData += _reward(l2);
					counter += _reward(l2);
				}
				// extra exp
				else if (_eventType(l1) == 1) {
					gameData += _reward(l2);
					counter += _reward(l2) << 32;
				}
				// extra exp and kongium
				else if (_eventType(l1) == 2) {
					gameData += ((_reward(l2) & (2 ** 64 - 1)) << 16) + ((_reward(l2) >> 64));
					counter += _reward(l2) & (2 ** 64 - 1);
					counter += (_reward(l2) >> 64) << 32;
				}
				// nft
				else if (_eventType(l1) == 3) {
					if (_tokenType(l1) == 1155) {
						if (IERC1155(_token(l1)).balanceOf(msg.sender, _reward(l2)) > _amount(l2)) {
							gameData += 1 << 32;
							rewardAddress[1] = _token(l1);
							tokenId[1] = _reward(l2);
							amounts[1] = _amount(l2);
							tokenTypes[1] = 1155;
						}
						else
							counter += 500;
					}
					else if (_tokenType(l1) == 20) {
						if (IERC20(_token(l1)).balanceOf(msg.sender) > _amount(l2)) {
							gameData += 1 << 32;
							rewardAddress[1] = _token(l1);
							amounts[1] = _amount(l2);
							tokenTypes[1] = 20;
						}
						else
							counter += 500;
					}
				}
			}
			gameData <<= 136;
			gameData += counter;
		}
	}

	function _vxInTeam(uint256 _team) internal pure returns(uint256) {
		uint _teamCount = 0;
		for (uint256 i = 0; i < 5; i++) {
			uint256 vxId = (_team >> (32 * i)) & 0xffffffff;
			_teamCount += vxId > 0 ? 1 : 0;
		}
		return _teamCount;
	}

	function _sumOfLevels(uint256[5] calldata _levels) internal pure returns(uint256 sum) {
		for(uint256 i = 0; i < 5; i++)
			sum += _levels[i];
	}

	function _maxLevel(uint256[5] calldata _levels) internal pure returns(uint256 max) {
		for(uint256 i = 0; i < 5; i++)
			if (_levels[i] > max)
				max = _levels[i];
	}

	function getReqForLvl(uint256 _currentLevel) external view override returns(uint256 exp, uint256 kongium) {
		if (_currentLevel == 1) {
			exp = 10;
			kongium = 10;
		}
		else if (_currentLevel == 2) {
			exp = 20;
			kongium = 40;
		}
		else if (_currentLevel == 3) {
			exp = 40;
			kongium = 60;
		}
		else if (_currentLevel == 4) {
			exp = 60;
			kongium = 100;
		}
		else if (_currentLevel == 5) {
			exp = 80;
			kongium = 150;
		}
		else if (_currentLevel == 6) {
			exp = 100;
			kongium = 200;
		}
		else if (_currentLevel == 7) {
			exp = 125;
			kongium = 250;
		}
		else if (_currentLevel == 8) {
			exp = 150;
			kongium = 400;
		}
		else if (_currentLevel == 9) {
			exp = 175;
			kongium = 500;
		}
		else if (_currentLevel == 10) {
			exp = 200;
			kongium = 600;
		}
		else if (_currentLevel == 11) {
			exp = 225;
			kongium = 700;
		}
		else if (_currentLevel == 12) {
			exp = 250;
			kongium = 800;
		}
		else if (_currentLevel == 13) {
			exp = 275;
			kongium = 900;
		}
		else if (_currentLevel == 14) {
			exp = 300;
			kongium = 1000;
		}
		else if (_currentLevel == 15) {
			exp = 325;
			kongium = 1200;
		}
		else if (_currentLevel == 16) {
			exp = 350;
			kongium = 1400;
		}
		else if (_currentLevel == 17) {
			exp = 400;
			kongium = 1600;
		}
		else if (_currentLevel == 18) {
			exp = 450;
			kongium = 1800;
		}
		else if (_currentLevel == 19) {
			exp = 500;
			kongium = 2000;
		}
		else{
			exp = uint256(-1);
			kongium = uint256(-1);
		}
	}

	function generateSeed(uint256 _seed) internal view returns(uint256 rand) {
		rand = uint256(keccak256(abi.encodePacked(_seed)));
	}

	function _eventType(uint256 _blob) internal pure returns(uint256) {
		return _blob >> 205;
	}

	function _charmRequirement(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 203) & 3; // 0b11
	}

	function _teamSize(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 200) & 7; // 0b111
	}

	function _singleLevel(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 195) & 31; // 0b11111
	}

	function _totalLevel(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 188) & 127; // 0b1111111
	}

	function _tokenType(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 177) & 2047; // 0b11111111111
	}

	function _chance(uint256 _blob) internal pure returns(uint256) {
		return (_blob >> 160) & 131071; // 0b11111111111111111
	}

	function _token(uint256 _blob) internal pure returns(address) {
		return address(uint160(_blob & 1461501637330902918203684832716283019655932542975));
	}

	function _reward(uint256 _blob) internal pure returns(uint256) {
		return _blob >> 128;
	}

	function _amount(uint256 _blob) internal pure returns(uint256) {
		return _blob & 0xffffffffffffffffffffffffffffffff;
	}
}

pragma solidity ^0.6.12;

import "IVRFCoordinator2.sol";
import "ILink.sol";
import "Ownable.sol";

abstract contract VRFConsumerBaseV2Mumbai is Ownable {

	struct RequestConfig {
		uint64 subId;
		uint32 callbackGasLimit;
		uint16 requestConfirmations;
		uint32 numWords;
		bytes32 keyHash;
	}

	RequestConfig public config;
	VRFCoordinatorV2Interface private COORDINATOR;
	LinkTokenInterface private LINK;


	/**
	* @param _vrfCoordinator address of VRFCoordinator contract
	*/
	// mumbai coord: 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
	// mumbai link:  0x326C977E6efc84E512bB9C30f76E30c160eD06FB
	constructor(address _vrfCoordinator, address _link) public {
		COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
		LINK = LinkTokenInterface(_link);
		
		config = RequestConfig({
			subId: 0,
			callbackGasLimit: 1000000,
			requestConfirmations: 3,
			numWords: 1,
			keyHash: 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
		});
	}

	function _initVRF(address _vrfCoordinator, address _link) internal {
		COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
		LINK = LinkTokenInterface(_link);
		
		config = RequestConfig({
			subId: 0,
			callbackGasLimit: 1000000,
			requestConfirmations: 3,
			numWords: 1,
			keyHash: 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
		});
	}

	/**
	* @notice fulfillRandomness handles the VRF response. Your contract must
	* @notice implement it. See "SECURITY CONSIDERATIONS" above for important
	* @notice principles to keep in mind when implementing your fulfillRandomness
	* @notice method.
	*
	* @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
	* @dev signature, and will call it once it has verified the proof
	* @dev associated with the randomness. (It is triggered via a call to
	* @dev rawFulfillRandomness, below.)
	*
	* @param requestId The Id initially returned by requestRandomness
	* @param randomWords the VRF output expanded to the requested number of words
	*/
	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

	// rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
	// proof. rawFulfillRandomness then calls fulfillRandomness, after validating
	// the origin of the call
	function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
		require (msg.sender == address(COORDINATOR), "!coordinator");
		fulfillRandomWords(requestId, randomWords);
	}

	  // Assumes the subscription is funded sufficiently.
	function requestRandomWords() internal returns(uint256 requestId) {
		RequestConfig memory rc = config;
		// Will revert if subscription is not set and funded.
		requestId = COORDINATOR.requestRandomWords(
			rc.keyHash,
			rc.subId,
			rc.requestConfirmations,
			rc.callbackGasLimit,
			rc.numWords
		);
	}

	function topUpSubscription(uint256 amount) external onlyOwner {
		LINK.transferAndCall(address(COORDINATOR), amount, abi.encode(config.subId));
	}

	function withdraw(uint256 amount, address to) external onlyOwner {
		LINK.transfer(to, amount);
	}

	function unsubscribe(address to) external onlyOwner {
		// Returns funds to this address
		COORDINATOR.cancelSubscription(config.subId, to);
		config.subId = 0;
	}

	function subscribe() public onlyOwner {
		// Create a subscription, current subId
		address[] memory consumers = new address[](1);
		consumers[0] = address(this);
		config.subId = COORDINATOR.createSubscription();
		COORDINATOR.addConsumer(config.subId, consumers[0]);
	}
}

pragma solidity ^0.6.12;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

pragma solidity ^0.6.12;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "IERC20.sol";
import "SafeMath.sol";
import "Ownable.sol";

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

contract KongzExtraData is Ownable {
	using SafeMath for uint256;

	mapping(address => bool) public approvedContracts;
	mapping(address => mapping(bytes32 => bool)) public approvecContractToStat;
	mapping(address => mapping(bytes32 => bool)) public approvecContractToItem;
	mapping(bytes32 => bool) internal enabledStats;
	mapping(bytes32 => bool) internal enabledItems;
	mapping(uint256 => mapping(bytes32 => uint256)) public stats;
	mapping(address => mapping(bytes32 => uint256)) public items;

	event StatIncreased(bytes32 indexed stat, uint256 indexed tokenId, uint256 amount);
	event StatDecreased(bytes32 indexed stat, uint256 indexed tokenId, uint256 amount);

	event ItemIncreased(bytes32 indexed item, address indexed user, uint256 amount);
	event ItemDecreased(bytes32 indexed item, address indexed user, uint256 amount);

	function updateStatContracts(address[] calldata _contracts, string[] calldata _statIds, bool[] calldata _vals) external onlyOwner {
		require(_contracts.length == _vals.length, "!len");

		for (uint256 i = 0 ; i < _contracts.length; i++) {
			approvecContractToStat[_contracts[i]][keccak256(abi.encodePacked(_statIds[i]))] = _vals[i];
		}
	}

	function updateItemContracts(address[] calldata _contracts, string[] calldata _itemIds, bool[] calldata _vals) external onlyOwner {
		require(_contracts.length == _vals.length, "!len");

		for (uint256 i = 0 ; i < _contracts.length; i++) {
			approvecContractToItem[_contracts[i]][keccak256(abi.encodePacked(_itemIds[i]))] = _vals[i];
		}
	}

	function adminUpdateStats(string[] calldata _stats, bool[] calldata _vals) external onlyOwner {
		require(_stats.length == _vals.length, "!len");

		for (uint256 i = 0 ; i < _stats.length; i++) {
			enabledStats[keccak256(abi.encodePacked(_stats[i]))] = _vals[i];
		}
	}

	function adminUpdateItems(string[] calldata _items, bool[] calldata _vals) external onlyOwner {
		require(_items.length == _vals.length, "!len");

		for (uint256 i = 0 ; i < _items.length; i++) {
			enabledItems[keccak256(abi.encodePacked(_items[i]))] = _vals[i];
		}
	}

	function incStats(string calldata _stat, uint256 _id, uint256 _amount) external {
		bytes32 statId = keccak256(abi.encodePacked(_stat));
		require(approvecContractToStat[msg.sender][statId] || msg.sender == owner(), "!stat");
		require(enabledStats[statId]);
		stats[_id][statId] = stats[_id][statId].add(_amount);
		emit StatIncreased(statId, _id, _amount);
	}

	function decStats(string calldata _stat, uint256 _id, uint256 _amount) external {
		bytes32 statId = keccak256(abi.encodePacked(_stat));
		require(approvecContractToStat[msg.sender][statId] || msg.sender == owner(), "!stat");
		require(enabledStats[statId]);
		stats[_id][statId] = stats[_id][statId].sub(_amount);
		emit StatDecreased(statId, _id, _amount);
	}

	function incStats(bytes32 _statId, uint256 _id, uint256 _amount) external {
		require(approvecContractToStat[msg.sender][_statId] || msg.sender == owner(), "!stat");
		require(enabledStats[_statId]);
		stats[_id][_statId] = stats[_id][_statId].add(_amount);
		emit StatIncreased(_statId, _id, _amount);
	}

	function decStats(bytes32 _statId, uint256 _id, uint256 _amount) external {
		require(approvecContractToStat[msg.sender][_statId] || msg.sender == owner(), "!stat");
		require(enabledStats[_statId]);
		stats[_id][_statId] = stats[_id][_statId].sub(_amount);
		emit StatDecreased(_statId, _id, _amount);
	}

	function incItem(string calldata _item, address _user, uint256 _amount) external {
		bytes32 itemId = keccak256(abi.encodePacked(_item));
		require(approvecContractToItem[msg.sender][itemId] || msg.sender == owner(), "!item");
		require(enabledItems[itemId]);
		items[_user][itemId] = items[_user][itemId].add(_amount);
		emit ItemIncreased(itemId, _user, _amount);
	}

	function decItem(string calldata _item, address _user, uint256 _amount) external {
		bytes32 itemId = keccak256(abi.encodePacked(_item));
		require(approvecContractToItem[msg.sender][itemId] || msg.sender == owner(), "!item");
		require(enabledItems[itemId]);
		items[_user][itemId] = items[_user][itemId].sub(_amount);
		emit ItemDecreased(itemId, _user, _amount);
	}

	function incItem(bytes32 _itemId, address _user, uint256 _amount) external {
		require(approvecContractToItem[msg.sender][_itemId] || msg.sender == owner(), "!item");
		require(enabledItems[_itemId]);
		items[_user][_itemId] = items[_user][_itemId].add(_amount);
		emit ItemIncreased(_itemId, _user, _amount);
	}

	function decItem(bytes32 _itemId, address _user, uint256 _amount) external {
		require(approvecContractToItem[msg.sender][_itemId] || msg.sender == owner(), "!item");
		require(enabledItems[_itemId]);
		items[_user][_itemId] = items[_user][_itemId].sub(_amount);
		emit ItemDecreased(_itemId, _user, _amount);
	}
}