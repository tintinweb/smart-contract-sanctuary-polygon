// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {MissionBase} from "./MissionBase.sol";

contract MissionImpl is MissionBase {
    
    uint public DISTANCE;

    uint[] public goldRewards;
    uint HOUSE = 1;
    uint GOOBER = 2;
    uint XOLO = 3;
    uint SHIP = 4;
    uint PIRATE = 75;
    uint LEGENDARY_GOVERNOR = 12;
    uint ULTRA_RARE_GOVERNOR = 13;
    uint RARE_GOVERNOR = 14;
    uint LEGENDARY_ERNESTO = 18;
    uint ULTRA_RARE_ERNESTO = 19;
    uint RARE_ERNESTO = 20;
    
    uint[] public silverRewards;
    uint SILVER_MINER = 1;
    uint COMMON_GOVERNOR = 16;
    uint COMMON_ERNESTO = 22;
    uint WOOD80 = 4;

    uint[] public bronzeRewards;
    uint BRONZE_MINER = 1;
    uint WOOD60 = 2;
    uint WOOD50 = 3;

    address[] public houseWinners;
    address[] public gooberWinners;
    address[] public xoloWinners;
    address[] public shipWinners;
    address[] public pirateWinners;
    address[] public minerWinners;

    bool bronzeMinted;
    bool silverMinted;
    bool goldMinted;

    constructor(
        address _wood,
        address _goldhunters, 
        address _ships, 
        address _cards,
        address _metadata,
        address _speedCalculator,
        address _vrfCoordinator, 
        address _linkToken, 
        bytes32 _keyHash, 
        uint _distance
    ) MissionBase(
        _wood,
        _goldhunters, 
        _ships, 
        _cards, 
        _metadata,
        _speedCalculator,
        _vrfCoordinator, 
        _linkToken, 
        _keyHash
    ) {
        DISTANCE = _distance;
        _pause();
    }

    ///// MODIFIERS /////

    modifier whenValidCrewSize(uint16[] calldata _goldhunterIds, uint16[] calldata _shipIds, uint[] calldata _cardIds) {
        require(_shipIds.length == 0, "ERROR: Ships cannot be used on this mission");
        require(_goldhunterIds.length >= 1, "ERROR: Crew Count Must Be At Least 1");
        require(_goldhunterIds.length <= 5, "ERROR: Crew Count Cannot be Greater Than 5");
        
        /* if (!metadata.shipIsPirate(_shipIds[0])) {
            require(_goldhunterIds.length <= 5, "ERROR: Max Capacity for Regular Ship is 5");
        } else {
            require(_goldhunterIds.length <= 7, "ERROR: Max Capacity for Pirate Ship is 7");
        } */

        require(_cardIds.length <= 3, "ERROR: Max Amount of GHG Cards Which Can be Used is 3");

        _;
    }

    ///// GAMEPLAY /////

    function setDistance(uint _distance) external onlyOwner {
        DISTANCE = _distance;
    }

    function startMission(
        uint16[] calldata _goldhunterIds, 
        uint16[] calldata _shipIds,
        uint[] calldata _cardIds
    ) public whenValidCrewSize(_goldhunterIds, _shipIds, _cardIds) {
        // uint speed = speedCalculator.getCrewSpeed(_goldhunterIds, _shipIds, _cardIds);
        uint speed = speedCalculator.getCrewSpeed(_goldhunterIds, _cardIds);
        _startMission(_goldhunterIds, _shipIds, _cardIds, speed, DISTANCE);
    }

    function finishMission(
        uint _missionId
    ) public {
        uint randomOutcome = _finishMission(_missionId);

        // 3 Outcomes, Earned Reward Yes/No, Class of Prize, Prize itself
        uint INDEPENDENT_OUTCOMES = 3;
        uint[] memory expandedValues = new uint[](INDEPENDENT_OUTCOMES);

        for (uint i = 0; i < INDEPENDENT_OUTCOMES; i++) {
            expandedValues[i] = uint(keccak256(abi.encode(randomOutcome, i)));
        }

        // 60% CHANCE OF SUCCESS
        if ((expandedValues[0] % 100) + 1 > (40)) {
            _sendReward(expandedValues[1], expandedValues[2], msg.sender);
        }
    }

    ///// REWARD MANAGEMENT /////
    function getHouseWinners() public view returns (address[] memory) {
        return houseWinners;
    }

    function getGooberWinners() public view returns (address[] memory) {
        return gooberWinners;
    }

    function getXoloWinners() public view returns (address[] memory) {
        return xoloWinners;
    }

    function getShipWinners() public view returns (address[] memory) {
        return shipWinners;
    }

    function getPirateWinners() public view returns (address[] memory) {
        return pirateWinners;
    }

    function getMinerWinners() public view returns (address[] memory) {
        return minerWinners;
    }

    event WonHouse(address _winner);
    event WonGoober(address _winner);
    event WonXolo(address _winner);
    event WonGHGCard(address _winner, string _cardName);
    event WonShip(address _winner);
    event WonPirate(address _winner);
    event WonMiner(address _winner);
    event WonWood(address _winner, uint _amount);
    event OutOfRewards(uint tier);

    function _sendReward(uint _tierOutcome, uint _rewardIxOutcome, address _winner) internal {
        if ((_tierOutcome % 100) + 1 <= 15) { // gold
            uint reward = _getReward(1, _rewardIxOutcome);

            if (reward == PIRATE) { // UNIT
                pirateWinners.push(_winner);
                emit WonPirate(_winner);
            } else if (reward == SHIP) { // UNIT
                shipWinners.push(_winner);
                emit WonShip(_winner);
            } else if (reward == RARE_ERNESTO) { // CARD
                cards.mint(_winner, RARE_ERNESTO, 1);
                emit WonGHGCard(_winner, "CHARACTER_ERNESTO_RARE");
            } else if (reward == RARE_GOVERNOR) { // CARD
                cards.mint(_winner, RARE_GOVERNOR, 1);
                emit WonGHGCard(_winner, "CHARACTER_ERNESTO_RARE");
            } else if (reward == ULTRA_RARE_ERNESTO) { // CARD
                cards.mint(_winner, ULTRA_RARE_ERNESTO, 1);
                emit WonGHGCard(_winner, "CHARACTER_ERNESTO_ULTRA_RARE");
            } else if (reward == ULTRA_RARE_GOVERNOR) { // CARD
                cards.mint(_winner, ULTRA_RARE_GOVERNOR, 1);
                emit WonGHGCard(_winner, "CHARACTER_GOVERNOR_ULTRA_RARE");
            } else if (reward == LEGENDARY_ERNESTO) { // CARD
                cards.mint(_winner, LEGENDARY_ERNESTO, 1);
                emit WonGHGCard(_winner, "CHARACTER_ERNESTO_LEGENDARY");
            } else if (reward == LEGENDARY_GOVERNOR) { // CARD
                cards.mint(_winner, LEGENDARY_GOVERNOR, 1);
                emit WonGHGCard(_winner, "CHARACTER_GOVERNOR_LEGENDARY");
            } else if (reward == XOLO) { // MANUAL LIST
                xoloWinners.push(_winner);
                emit WonXolo(_winner);
            } else if (reward == GOOBER) { // MANUAL LIST
                gooberWinners.push(_winner);
                emit WonGoober(_winner);
            } else if (reward == HOUSE) { // MANUAL LIST
                houseWinners.push(_winner);
                emit WonHouse(_winner);
            } else {
                emit OutOfRewards(1);
            }

        } else if ((_tierOutcome % 100) + 1 < 50) { // silver
            uint reward = _getReward(2, _rewardIxOutcome);

            if (reward == SILVER_MINER) { // UNIT 
                minerWinners.push(_winner);
                emit WonMiner(_winner);
            } else if (reward == COMMON_GOVERNOR) { // CARD
                cards.mint(_winner, COMMON_GOVERNOR, 1);
                emit WonGHGCard(_winner, "CHARACTER_GOVERNOR_COMMON");
            } else if (reward == COMMON_ERNESTO) { // CARD
                cards.mint(_winner, COMMON_ERNESTO, 1);
                emit WonGHGCard(_winner, "CHARACTER_ERNESTO_COMMON");
            } else if (reward == WOOD80) { // COIN
                wood.mint(_winner, 80000 ether);
                emit WonWood(_winner, 80000 ether);
            } else {
                emit OutOfRewards(2);
            }

        } else {
            uint reward = _getReward(3, _rewardIxOutcome);

            if (reward == BRONZE_MINER) { // UNIT
                minerWinners.push(_winner);
                emit WonMiner(_winner);
            } else if (reward == WOOD60) { // COIN
                wood.mint(_winner, 60000 ether);
                emit WonWood(_winner, 60000 ether);
            } else if (reward == WOOD50) { // COIN
                wood.mint(_winner, 50000 ether);
                emit WonWood(_winner, 50000 ether);
            } else {
                emit OutOfRewards(3);
            }
        }
    }

    function _getReward(uint _rewardTier, uint _seed) internal returns (uint reward) {
        if (_rewardTier == 3) { // bronze
            if ( bronzeRewards.length != 0 ) {
                uint rewardIx = _seed % bronzeRewards.length;
                reward = bronzeRewards[rewardIx];

                bronzeRewards[rewardIx] = bronzeRewards[bronzeRewards.length - 1];
                bronzeRewards.pop();
            } else { 
                return 0;
            }
        } else if (_rewardTier == 2) { // silver
            if ( silverRewards.length != 0 ) {
                uint rewardIx = _seed % silverRewards.length;
                reward = silverRewards[rewardIx];

                silverRewards[rewardIx] = silverRewards[silverRewards.length - 1];
                silverRewards.pop();
            } else {
                return 0;
            }
        } else { // gold
            if ( goldRewards.length != 0 ) {
                uint rewardIx = _seed % goldRewards.length;
                reward = goldRewards[rewardIx];

                goldRewards[rewardIx] = goldRewards[goldRewards.length - 1];
                goldRewards.pop();
            } else {
                return 0;
            }
        }
    }

    function mintGoldRewards() external {
        require(!goldMinted, "ERROR: GOLD REWARDS HAVE BEEN MINTED");

        goldRewards.push(HOUSE);
        goldRewards.push(LEGENDARY_GOVERNOR);
        goldRewards.push(LEGENDARY_ERNESTO);
        
        for (uint i = 0; i < 2; i++) {
            goldRewards.push(GOOBER);
        }

        for (uint i = 0; i < 2; i++) {
            goldRewards.push(XOLO);
        }

        for (uint i = 0; i < 3; i++) {
            goldRewards.push(SHIP);
        }

        for (uint i = 0; i < 3; i++) {
            goldRewards.push(PIRATE);
        }

        for (uint i = 0; i < 10; i++) {
            goldRewards.push(ULTRA_RARE_GOVERNOR);
        }

        for (uint i = 0; i < 10; i++) {
            goldRewards.push(ULTRA_RARE_ERNESTO);
        }

        for (uint i = 0; i < 55; i++) {
            goldRewards.push(RARE_GOVERNOR);
        }

        for (uint i = 0; i < 55; i++) {
            goldRewards.push(RARE_ERNESTO);
        }

        goldMinted = true;
    }

    function mintSilverRewards() external {
        require(!silverMinted, "ERROR: SILVER REWARDS HAVE BEEN MINTED");

        for (uint i = 0; i < 13; i++) {
            silverRewards.push(SILVER_MINER);
        }

        for (uint i = 0; i < 100; i++) {
            silverRewards.push(COMMON_GOVERNOR);
        }

        for (uint i = 0; i < 100; i++) {
            silverRewards.push(COMMON_ERNESTO);
        }

        for (uint i = 0; i < 120; i++) {
            silverRewards.push(WOOD80);
        }

        silverMinted = true;
    }

    function mintBronzeRewards() external {
        require(!bronzeMinted, "ERROR: BRONZE REWARDS HAVE BEEN MINTED");

        for (uint i = 0; i < 5; i++) {
            bronzeRewards.push(BRONZE_MINER);
        }

        for (uint i = 0; i < 175; i++) {
            bronzeRewards.push(WOOD60);
        }

        for (uint i = 0; i < 295; i++) {
            bronzeRewards.push(WOOD50);
        }

        bronzeMinted = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {InterfaceManager} from "./InterfaceManager.sol";
import {Recoverable} from "../../../utils/Recoverable.sol";

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {VRFConsumerBase} from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

abstract contract MissionBase is Pausable, Recoverable, VRFConsumerBase, InterfaceManager {

    ///// STRUCTS /////
    struct Mission {
        address owner;
        uint missionId;
        uint completionTime;
        uint16[] goldhunterIds;
        uint16[] shipIds;
        uint[] cardIds;
        uint randomOutcome;
        bool gotChainlinkResponse;
    }

    ///// EVENTS /////
    event MissionStarted(uint missionId, uint crewSpeed, uint16[] goldhunterIds, uint16[] shipIds);

    //uint outcomeIx;
    uint missionIdCounter;
    //uint[] pendingOutcomes;
    mapping(uint => uint) missionIxById;
    mapping(uint => Mission) missionsById;
    mapping(address => uint[]) public playerMissionIds;
    mapping(bytes32 => uint) public requestIdToMissionId;
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    constructor(
        address _wood, 
        address _goldhunters, 
        address _ships, 
        address _cards, 
        address _metadata,
        address _speedCalculator,
        address _vrfCoordinator, 
        address _linkToken, 
        bytes32 _keyHash
    )   VRFConsumerBase(
            _vrfCoordinator,
            _linkToken
        )
        InterfaceManager(
            _wood,
            _goldhunters,
            _ships,
            _cards,
            _metadata,
            _speedCalculator
        )
    {
        keyHash = _keyHash;
        fee = .0001 * 10 ** 18;

        //outcomeIx = 0;
        missionIdCounter = 0;
    }

    ///// VIEW FUNCTIONS /////
    function getPlayerMissions(address _player) public view returns (Mission[] memory) {
        uint[] memory playersMissionIds = playerMissionIds[_player];
        Mission[] memory missions;
        for(uint i=0; i < playersMissionIds.length; i++) {
            missions[i] = missionsById[playersMissionIds[i]];
        }
        return missions;
    }

    ///// OWNER FUNCTIONS /////
    function unpause() external onlyOwner {
        require(LINK.balanceOf(address(this)) >= fee, "ERROR: Contract is out of LINK - please alert the developers if you encounter this");
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }
    
    ///// MISSION FUNCTIONS /////
    function _startMission(
        uint16[] calldata _goldhunterIds, 
        uint16[] calldata _shipIds,
        uint[] calldata _cardIds,
        uint _crewSpeed, 
        uint _distance
    ) internal whenNotPaused {
        missionsById[missionIdCounter] = Mission({
            owner: msg.sender,
            missionId: missionIdCounter,
            completionTime: block.timestamp + _distance / _crewSpeed * 1 minutes,
            goldhunterIds: _goldhunterIds,
            shipIds: _shipIds,
            cardIds: _cardIds,
            randomOutcome: 0,
            gotChainlinkResponse: false
        });

        // Save the index position for a given player's mission in missionIxById to reference when unstaking
        missionIxById[missionIdCounter] = playerMissionIds[msg.sender].length; 
        playerMissionIds[msg.sender].push(missionIdCounter);

        for(uint i = 0; i < _goldhunterIds.length; i++) {
            goldhunters.safeTransferFrom(msg.sender, address(this), _goldhunterIds[i]);
        }

        for(uint i = 0; i < _shipIds.length; i++) {
            ships.safeTransferFrom(msg.sender, address(this), _shipIds[i]);
        }

        for(uint i = 0; i < _cardIds.length; i++) {
            cards.safeTransferFrom(msg.sender, address(this), _cardIds[i], 1, "");
        }

        _getRandomNumber(missionIdCounter);
        emit MissionStarted(missionIdCounter, _crewSpeed, _goldhunterIds, _shipIds);

        missionIdCounter ++;
    }

    function _finishMission(uint _missionId) internal returns (uint randomOutcome) {
        Mission memory mission = missionsById[_missionId];
        
        require(mission.owner == msg.sender, "ERROR: Transaction Sender is not Mission Owner");
        require(mission.gotChainlinkResponse, "ERROR: Have not received response from Chainlink");
        require(block.timestamp >= mission.completionTime, "ERROR: The mission has not concluded yet");

        for(uint i = 0; i < mission.goldhunterIds.length; i++) {
            goldhunters.safeTransferFrom(address(this), mission.owner, mission.goldhunterIds[i]);
        }

        for(uint i = 0; i < mission.shipIds.length; i++) {
            ships.safeTransferFrom(address(this), mission.owner, mission.shipIds[i]);
        }

        for(uint i = 0; i < mission.cardIds.length; i++) {
            cards.safeTransferFrom(address(this), mission.owner, mission.cardIds[i], 1, "");
        }

        if (playerMissionIds[msg.sender].length > 1) {
            uint missionIx = missionIxById[_missionId];
            uint lastMissionId = playerMissionIds[msg.sender][playerMissionIds[msg.sender].length - 1];

            // Replace finished mission with last mission, then pop last element
            playerMissionIds[msg.sender][missionIx] = lastMissionId;
            missionIxById[lastMissionId] = missionIx;
        }

        playerMissionIds[msg.sender].pop();

        return mission.randomOutcome;
    }

    ///// CHAINLINK RANDOMNESS FUNCTIONS /////
    function withdraw() external onlyOwner {
        LINK.transferFrom(address(this), msg.sender, LINK.balanceOf(address(this)));
    }

    function _getRandomNumber(uint _missionId) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "ERROR: Contract is out of LINK - please alert the developers if you encounter this");
        requestId =  requestRandomness(keyHash, fee);
        requestIdToMissionId[requestId] = _missionId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 _randomness) internal override {
        missionsById[requestIdToMissionId[requestId]].randomOutcome = _randomness;
        missionsById[requestIdToMissionId[requestId]].gotChainlinkResponse = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ICoin, IToken, ICard, IGHGMetadata, SpeedCalculator} from "../../../interfaces/Interfaces.sol";

contract InterfaceManager {

    ICoin public wood;
    IToken public goldhunters;
    IToken public ships;
    ICard public cards;
    IGHGMetadata public metadata;
    SpeedCalculator public speedCalculator;

    constructor(
        address _wood, 
        address _goldhunters,
        address _ships,
        address _cards,
        address _metadata,
        address _speedCalculator
    ) {
        wood = ICoin(_wood);
        goldhunters = IToken(_goldhunters);
        ships = IToken(_ships);
        cards = ICard(_cards);
        metadata = IGHGMetadata(_metadata);
        speedCalculator = SpeedCalculator(_speedCalculator);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)
pragma solidity ^0.8.0;

import {IToken, ICard} from "../interfaces/Interfaces.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/**
 * @dev Implementation of the {IERC721Receiver} and {IERC1155Receiver} interfaces.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract Recoverable is Ownable, ERC721Holder, ERC1155Holder {

    /**
     * @dev Allows for the safeTransfer of ALL assets from this contract to a list of recipients
     */
    function transferOut(
        bool[] calldata _isERC721,
        address[] calldata _tokenAddressesToTransfer, 
        address[] calldata _recipients, 
        uint[] calldata _tokenIds, 
        uint[] calldata _amounts, 
        bytes[] calldata _data
    ) external onlyOwner {
        require(
            (_isERC721.length == _tokenAddressesToTransfer.length) 
            && (_tokenAddressesToTransfer.length == _recipients.length) 
            && (_recipients.length == _tokenIds.length)
            && (_tokenIds.length == _amounts.length) 
            && (_amounts.length == _data.length), "ERROR: INVALID INPUT DATA - MISMATCHED LENGTHS");

        for(uint i = 0; i < _recipients.length; i++) {
            if (_isERC721[i]) {
                IToken(_tokenAddressesToTransfer[i]).safeTransferFrom(address(this), _recipients[i], _tokenIds[i]);
            } else {
                ICard(_tokenAddressesToTransfer[i]).safeTransferFrom(address(this), _recipients[i], _tokenIds[i], _amounts[i], _data[i]);
            }
        }
    }
    
    /**
     * @dev Allows for the safeTransfer of all ERC721 assets from this contract to a list of recipients
     */
    function transferOut721(
        address[] calldata _tokenAddressesToTransfer, 
        address[] calldata _recipients, 
        uint[] calldata _tokenIds
    ) external onlyOwner {
        require(
            (_tokenAddressesToTransfer.length == _recipients.length) 
            && (_recipients.length == _tokenIds.length), 
            "ERROR: INVALID INPUT DATA - MISMATCHED LENGTHS");

        for(uint i = 0; i < _recipients.length; i++) {
            IToken(_tokenAddressesToTransfer[i]).safeTransferFrom(address(this), _recipients[i], _tokenIds[i]);
        }
    }

    /**
     * @dev Allows for the safeTransfer of all ERC1155 assets from this contract to a list of recipients
     */
    function transferOut1155(
        address[] calldata _tokenAddressesToTransfer, 
        address[] calldata _recipients, 
        uint[] calldata _tokenIds, 
        uint[] calldata _amounts, 
        bytes[] calldata _data
    ) external onlyOwner {
        require(
            (_tokenAddressesToTransfer.length == _recipients.length) 
            && (_recipients.length == _tokenIds.length)
            && (_tokenIds.length == _amounts.length) 
            && (_amounts.length == _data.length), 
            "ERROR: INVALID INPUT DATA - MISMATCHED LENGTHS");

        for(uint i = 0; i < _recipients.length; i++) {
            ICard(_tokenAddressesToTransfer[i]).safeTransferFrom(address(this), _recipients[i], _tokenIds[i], _amounts[i], _data[i]);
        }
    }

    /**
     * @dev Allows for the safeTransfer of a batch of ERC1155 assets from this contract to a recipient
     */
    function transferOut1155Batch(
        address _tokenAddressToTransfer, 
        address _recipient, 
        uint[] calldata _tokenIds, 
        uint[] calldata _amounts, 
        bytes calldata _data
    ) external onlyOwner {
        require(_tokenIds.length == _amounts.length, "ERROR: INVALID INPUT DATA - MISMATCHED LENGTHS");
        ICard(_tokenAddressToTransfer).safeBatchTransferFrom(address(this), _recipient, _tokenIds, _amounts, _data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

interface ICoin {
    function mint(address account, uint amount) external;
    function burn(address _from, uint _amount) external;
    function balanceOf(address account) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IToken {
    function ownerOf(uint id) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function isApprovedForAll(address owner, address operator) external returns(bool);
    function setApprovalForAll(address operator, bool approved) external;
}

interface ICard {
    function getSeriesName(uint _id) external view returns (string memory _name);
    function safeTransferFrom(address from, address to, uint tokenId, uint amount, bytes memory data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function mint(address _to, uint _id, uint _amount) external;
}

interface IGHGMetadata {
    ///// GENERIC GETTERS /////
    function getGoldhunterMetadata(uint16 _tokenId) external view returns (string memory);
    function getShipMetadata(uint16 _tokenId) external view returns (string memory);
    function getHouseMetadata(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - SHIPS /////
    function shipIsPirate(uint16 _tokenId) external view returns (bool);
    function shipIsCrossedTheOcean(uint16 _tokenId) external view returns (bool);
    function getShipBackground(uint16 _tokenId) external view returns (string memory);
    function getShipShip(uint16 _tokenId) external view returns (string memory);
    function getShipFlag(uint16 _tokenId) external view returns (string memory);
    function getShipMast(uint16 _tokenId) external view returns (string memory);
    function getShipAnchor(uint16 _tokenId) external view returns (string memory);
    function getShipSail(uint16 _tokenId) external view returns (string memory);
    function getShipWaves(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - HOUSES /////
    function getHouseBackground(uint16 _tokenId) external view returns (string memory);
    function getHouseType(uint16 _tokenId) external view returns (string memory);
    function getHouseWindow(uint16 _tokenId) external view returns (string memory);
    function getHouseDoor(uint16 _tokenId) external view returns (string memory);
    function getHouseRoof(uint16 _tokenId) external view returns (string memory);
    function getHouseForeground(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - GOLDHUNTERS /////
    function goldhunterIsCrossedTheOcean(uint16 _tokenId) external view returns (bool);
    function goldhunterIsPirate(uint16 _tokenId) external view returns (bool);
    function getGoldhunterIsGen0(uint16 _tokenId) external pure returns (bool);
    function getGoldhunterSkin(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterLegs(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterFeet(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterTshirt(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHeadwear(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterMouth(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterNeck(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterSunglasses(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterTool(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterPegleg(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHook(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterDress(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterFace(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterPatch(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterEars(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHead(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterArm(uint16 _tokenId) external view returns (string memory);
}

interface SpeedCalculator {
    function getCrewSpeed(uint16[] calldata _goldhunterIds, uint[] calldata _cardIds) external view returns (uint speed);
    function getCrewSpeed(uint16[] calldata _goldhunterIds, uint16[] calldata _shipIds, uint[] calldata _cardIds) external view returns (uint speed);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}