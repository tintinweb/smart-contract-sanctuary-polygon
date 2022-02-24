// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

import {ICoin} from "../erc20/ICoin.sol";
import {IToken} from "../erc721/IToken.sol";
import {IGHGMetadata} from "../metadata/IGHGMetadata.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract pNewLand is Ownable, Pausable, ERC721Holder, ERC1155Holder {

    ///// INTERFACES /////
    ICoin public wood;
    IToken public ships;
    IToken public goldhunter;
    IGHGMetadata public metadata;
    
    ///// STRUCTS /////
    struct RewardRate {
        uint128 minerRate;
        uint128 shipRate;
        uint128 pirateShipRate;
        uint128 startTime;
    }

    struct Stake {
        uint16 tokenId;
        uint16 currentRewardRateIx;
        uint128 startTime;
    }

    ///// CONTRACT VARIABLES /////
    // Global Stat Fields
    uint public totalWoodClaimed;
    uint public unaccountedRewards;
    uint public totalGoldMinerStaked;
    uint public totalShipStaked;
    uint public totalPirateStaked;
    uint public tokenStolenCounter;
    uint128 public pirateReward;

    // Contract Configuration
    bool public zeroClaim; // enables the ability zero out all possible claims
    uint public taxPercentage; // sets the tax percentage which miners/ships pay when claiming wood
    uint public minTimeToExit; // sets the minimum amount of time a unit must wait from its last claim before it can be unstaked
    bool public bypassMinerUnstakePenalty; // enables bypassing the 50% chance of total loss of Wood when unstaking units

    // Staking Mechanics
    RewardRate[] public rewardRates;
    mapping(uint => uint) shipIndices;
    mapping(uint => uint) goldMinerIndices;
    mapping(uint => uint) pirateIndices;
    mapping(address => Stake[]) public goldMinerStake;
    mapping(address => Stake[]) public pirateStake;
    mapping(address => Stake[]) public shipStake;

    // Steal Mechanics
    mapping(address => uint) pirateHolderIndex;
    address[] pirateHolders;

    ///// EVENTS /////
    event TokenStolen(address owner, uint16 tokenId, address thief);
    event LandTokenStaked(address owner, uint16 tokenId, uint value);
    event ShipClaimed(uint16 tokenId, uint earned, bool unstaked);
    event GoldMinerClaimed(uint16 tokenId, uint earned, bool unstaked);
    event PirateClaimed(uint16 tokenId, uint earned, bool unstaked);

    ///// CONSTRUCTOR /////
    constructor(
        address _metadata,
        address _ships,
        address _goldhunter,
        address _wood
    ) {
        metadata = IGHGMetadata(_metadata);
        ships = IToken(_ships);
        goldhunter = IToken(_goldhunter);
        wood = ICoin(_wood);
        
        rewardRates.push(
            RewardRate({
                startTime: uint128(block.timestamp),
                minerRate: 2000 ether,
                shipRate: 4000 ether,
                pirateShipRate: 6000 ether
            })
        );

        taxPercentage = 20;
        minTimeToExit = 2 days;
        zeroClaim = false;
        bypassMinerUnstakePenalty = false;

        _pause();
    }

    ///// OWNER FUNCTIONS /////
    function unpause() external onlyOwner {
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function setTaxPercentage(uint _taxPercentage) external onlyOwner {
        taxPercentage = _taxPercentage;
    }

    function setMinTimeToExit(uint _minTimeToExit) external onlyOwner {
        minTimeToExit = _minTimeToExit;
    }

    function setZeroClaim(bool _zeroClaim) external onlyOwner {
        zeroClaim = _zeroClaim;
    }

    function setBypassMinerUnstakePenalty(bool _bypassMinerUnstakePenalty) external onlyOwner {
        bypassMinerUnstakePenalty = _bypassMinerUnstakePenalty;
    }

    function setGHGMetadata(address _ghgMetadata) external onlyOwner {
        metadata = IGHGMetadata(_ghgMetadata);
    }

    function pushNewRewardRate( 
        uint128 _minerRate,
        uint128 _shipRate,
        uint128 _pirateShipRate
    ) external onlyOwner {
        rewardRates.push(RewardRate({
            minerRate: _minerRate,
            shipRate: _shipRate,
            pirateShipRate: _pirateShipRate,
            startTime: uint128(block.timestamp)
        }));
    }

    function updateRewardRate(
        uint _rewardRateIx, 
        uint128 _startTime, 
        uint128 _minerRate,
        uint128 _shipRate,
        uint128 _pirateShipRate
    ) external onlyOwner {
        rewardRates[_rewardRateIx] = RewardRate({
            startTime: _startTime,
            minerRate: _minerRate,
            shipRate: _shipRate,
            pirateShipRate: _pirateShipRate
        });
    }

    ///// STAKING FUNCTIONS /////
    // This function can be called by any token owner, and used to stake tokens on behalf of the supplied address
    function stakeTokens(address _account, uint16[] calldata _goldhunterIds, uint16[] calldata _shipIds) external whenNotPaused {
        // Handle GoldHunters
        for(uint i = 0; i < _goldhunterIds.length; i++) {
            require(goldhunter.ownerOf(_goldhunterIds[i]) == msg.sender, "ERROR: NFT Does Not Belong to Transaction Sender");
            
            if (metadata.goldhunterIsPirate(_goldhunterIds[i])) {
                _stakePirate(_account, _goldhunterIds[i]);
            } else {
                _stakeGoldMiner(_account, _goldhunterIds[i]);
            }

            goldhunter.safeTransferFrom(msg.sender, address(this), _goldhunterIds[i]);
        }

        // Handle Ships
        for(uint i = 0; i < _shipIds.length; i++) {
            require(ships.ownerOf(_shipIds[i]) == msg.sender, "ERROR: NFT Does Not Belong to Transaction Sender");
            _stakeShip(_account, _shipIds[i]);
            ships.safeTransferFrom(msg.sender, address(this), _shipIds[i]);
        }
    }

    function _stakeGoldMiner(address _account, uint16 _tokenId) internal {
        totalGoldMinerStaked += 1;

        goldMinerIndices[_tokenId] = goldMinerStake[_account].length;
        goldMinerStake[_account].push(Stake({
            tokenId: uint16(_tokenId),
            currentRewardRateIx: uint16(rewardRates.length - 1),
            startTime: uint128(block.timestamp)
        }));

        emit LandTokenStaked(_account, _tokenId, block.timestamp);
    }

    function _stakePirate(address _account, uint16 _tokenId) internal {
        totalPirateStaked += 1;

        // If account already has some pirates no need to push it to the tracker
        if (pirateStake[_account].length == 0) {
            pirateHolderIndex[_account] = pirateHolders.length;
            pirateHolders.push(_account);
        }

        pirateIndices[_tokenId] = pirateStake[_account].length;
        pirateStake[_account].push(Stake({
            tokenId: uint16(_tokenId),
            currentRewardRateIx: uint16(rewardRates.length - 1),
            startTime: uint128(pirateReward)
        }));

        emit LandTokenStaked(_account, _tokenId, block.timestamp);
    }

    function _stakeShip(address _account, uint16 _tokenId) internal {
        totalShipStaked += 1;

        shipIndices[_tokenId] = shipStake[_account].length;
        shipStake[_account].push(Stake({
            tokenId: uint16(_tokenId),
            currentRewardRateIx: uint16(rewardRates.length - 1),
            startTime: uint128(block.timestamp)
        }));

        emit LandTokenStaked(_account, _tokenId, block.timestamp);
    }

    ///// CLAIMING/UNSTAKING FUNCTIONS /////
    function claimFromTokens(uint16[] calldata _goldhunterIds, uint16[] calldata _shipIds, bool unstake) external {
        uint owed = 0;
        
        for (uint i = 0; i < _goldhunterIds.length; i++) {
            if (metadata.goldhunterIsPirate(_goldhunterIds[i])) {
                owed += _claimFromPirate(_goldhunterIds[i], unstake);
            } else {
                owed += _claimFromMiner(_goldhunterIds[i], unstake);
            }
        }

        for (uint i = 0; i < _shipIds.length; i++) {
            owed += _claimFromShip(_shipIds[i], unstake);
        }

        if (owed == 0) return;

        totalWoodClaimed += owed;
        wood.mint(msg.sender, owed);
    }

    function _claimFromMiner(uint16 _tokenId, bool _unstake) internal returns (uint owed) {
        Stake memory stake = goldMinerStake[msg.sender][goldMinerIndices[_tokenId]];
        require(!(_unstake && block.timestamp - stake.startTime < minTimeToExit), "ERROR: Must Wait 2 Days from Last Claim Before Unstaking");

        owed = zeroClaim ? 0 : _getOwedToMiner(stake.startTime, stake.currentRewardRateIx);

        if (_unstake) {
            bool stolen = false;
            address luckyPirate;
            if (_tokenId >= 10000) {
                if (_getSomeRandomNumber(_tokenId, 100) <= 5) {
                    luckyPirate = _randomPirateOwner();
                    if (luckyPirate != address(0x0) && luckyPirate != msg.sender) {
                        stolen = true;
                    }
                }
            }
            if (_getSomeRandomNumber(_tokenId, 100) <= 50 && !bypassMinerUnstakePenalty) {
                _payTax(owed);
                owed = 0;
            }
            totalGoldMinerStaked -= 1;

            Stake memory lastStake = goldMinerStake[msg.sender][goldMinerStake[msg.sender].length - 1];
            goldMinerStake[msg.sender][goldMinerIndices[_tokenId]] = lastStake;
            goldMinerIndices[lastStake.tokenId] = goldMinerIndices[_tokenId];
            goldMinerStake[msg.sender].pop();
            delete goldMinerIndices[_tokenId];

            if (!stolen) {
                goldhunter.safeTransferFrom(address(this), msg.sender, _tokenId, "");
            } else {
                if (!goldhunter.isApprovedForAll(address(this), luckyPirate)) {
                    goldhunter.setApprovalForAll(luckyPirate, true);
                }
                goldhunter.safeTransferFrom(address(this), luckyPirate, _tokenId, "");
                emit TokenStolen(msg.sender, _tokenId, luckyPirate);
                tokenStolenCounter += 1;
            }

        } else {
            _payTax((owed * taxPercentage) / 100);
            owed = (owed * (100 - taxPercentage)) / 100;
            goldMinerStake[msg.sender][goldMinerIndices[_tokenId]] = _getFullyClaimedStake(_tokenId, block.timestamp);
        }

        emit GoldMinerClaimed(_tokenId, owed, _unstake);
    }

    function _claimFromPirate(uint16 _tokenId, bool unstake) internal returns (uint owed) {
        Stake memory stake = pirateStake[msg.sender][pirateIndices[_tokenId]];

        owed = zeroClaim ? 0 : _getOwedToPirate(stake.startTime);

        if (unstake == true) {
            totalPirateStaked -= 1;

            Stake memory lastStake = pirateStake[msg.sender][pirateStake[msg.sender].length - 1];
            pirateStake[msg.sender][pirateIndices[_tokenId]] = lastStake;
            pirateIndices[lastStake.tokenId] = pirateIndices[_tokenId];
            pirateStake[msg.sender].pop();
            delete pirateIndices[_tokenId];
            _updatePirateOwnerAddressList(msg.sender);

            goldhunter.safeTransferFrom(address(this), msg.sender, _tokenId, "");
        } else {
            pirateStake[msg.sender][pirateIndices[_tokenId]] = _getFullyClaimedStake(_tokenId, pirateReward);
        }
        emit PirateClaimed(_tokenId, owed, unstake);
    }

    function _claimFromShip(uint16 _shipId, bool _unstake) internal returns (uint owed) {
        Stake memory stake = shipStake[msg.sender][shipIndices[_shipId]];
        require(!(_unstake && block.timestamp - stake.startTime < minTimeToExit), "ERROR: Must Wait 2 Days from Last Claim Before Unstaking");
    
        if (metadata.shipIsPirate(_shipId)) {
            owed = zeroClaim ? 0 : _getOwedToPirateShip(stake.startTime, stake.currentRewardRateIx);
        } else {
            owed = zeroClaim ? 0 : _getOwedToRegularShip(stake.startTime, stake.currentRewardRateIx);
        }

        _payTax((owed * taxPercentage) / 100);
        owed = (owed * (100 - taxPercentage)) / 100;

        if (_unstake == true) {
            totalShipStaked -= 1;

            Stake memory lastStake = shipStake[msg.sender][shipStake[msg.sender].length - 1];
            shipStake[msg.sender][shipIndices[_shipId]] = lastStake;
            shipIndices[lastStake.tokenId] = shipIndices[_shipId];
            shipStake[msg.sender].pop();
            delete shipIndices[_shipId];

            ships.safeTransferFrom(address(this), msg.sender, _shipId, "");
        } else {
            shipStake[msg.sender][shipIndices[_shipId]] = _getFullyClaimedStake(_shipId, block.timestamp);
        }

        emit ShipClaimed(_shipId, owed, _unstake);
    }

    // Iterates through every rewardRate from the current position to the latest rewardRate and sums the results
    function _getOwedToMiner(uint _startTime, uint _currentRewardRateIx) internal view returns (uint owed) {
        for(uint i = _currentRewardRateIx; i < rewardRates.length; i++) {
            if (i == rewardRates.length - 1) {
                owed += ((block.timestamp - _startTime) * rewardRates[i].minerRate) / 1 days;
            } else {
                uint nextStartTime = rewardRates[i+1].startTime;
                owed += ((nextStartTime - _startTime) * rewardRates[i].minerRate) / 1 days;
                _startTime = nextStartTime;
            }
        }
    }

    function _getOwedToPirate(uint _startTime) internal view returns (uint owed) {
        owed = pirateReward - _startTime;
    }

    function _getOwedToRegularShip(uint _startTime, uint _currentRewardRateIx) internal view returns (uint owed) {
        for(uint i = _currentRewardRateIx; i < rewardRates.length; i++) {
            if (i == rewardRates.length - 1) {
                owed += ((block.timestamp - _startTime) * rewardRates[i].shipRate) / 1 days;
            } else {
                uint nextStartTime = rewardRates[i+1].startTime;
                owed += ((nextStartTime - _startTime) * rewardRates[i].shipRate) / 1 days;
                _startTime = nextStartTime;
            }
        }
    }

    function _getOwedToPirateShip(uint _startTime, uint _currentRewardRateIx) internal view returns (uint owed) {
        for(uint i = _currentRewardRateIx; i < rewardRates.length; i++) {
            if (i == rewardRates.length - 1) {
                owed += ((block.timestamp - _startTime) * rewardRates[i].pirateShipRate) / 1 days;
            } else {
                uint nextStartTime = rewardRates[i+1].startTime;
                owed += ((nextStartTime - _startTime) * rewardRates[i].pirateShipRate) / 1 days;
                _startTime = nextStartTime;
            }
        }
    }

    ///// INTERNAL HELPER FUNCTIONS /////
    function _getFullyClaimedStake(uint _tokenId, uint _startTime) internal view returns (Stake memory) {
        return Stake({
            tokenId: uint16(_tokenId),
            currentRewardRateIx: uint16(rewardRates.length - 1),
            startTime: uint128(_startTime)
        });
    }

    function _payTax(uint _amount) internal {
        if (totalPirateStaked == 0) {
            unaccountedRewards += _amount;
            return;
        }

        pirateReward += uint128((_amount + unaccountedRewards) / totalPirateStaked);
        unaccountedRewards = 0;
    }

    function _updatePirateOwnerAddressList(address account) internal {
        if (pirateStake[account].length != 0) {
            return; // No need to update holders
        }

        // Update the address list of holders, account unstaked all pirates
        address lastOwner = pirateHolders[pirateHolders.length - 1];
        pirateHolderIndex[lastOwner] = pirateHolderIndex[account];
        pirateHolders[pirateHolderIndex[account]] = lastOwner;
        pirateHolders.pop();
        delete pirateHolderIndex[account];
    }

    function _getSomeRandomNumber(uint _seed, uint _limit) internal view returns (uint16) {
        uint random = uint(
            keccak256(
                abi.encodePacked(
                    _seed,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    block.timestamp,
                    msg.sender
                )
            )
        );

        return uint16(random % _limit);
    }

    function _randomPirateOwner() internal view returns (address) {
        if (totalPirateStaked == 0) return address(0x0);

        uint holderIndex = _getSomeRandomNumber(totalPirateStaked, pirateHolders.length);

        return pirateHolders[holderIndex];
    }

}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

interface ICoin {
    function mint(address account, uint amount) external;
    function burn(address _from, uint _amount) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

interface IToken {
    function ownerOf(uint id) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) external;
    function isApprovedForAll(address owner, address operator) external returns(bool);
    function setApprovalForAll(address operator, bool approved) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

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