// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {FxBaseChildTunnel} from "../fx-portal/tunnel/FxBaseChildTunnel.sol";
import {SecuredBase} from "../0xbb/SecuredBase.sol";

import {IBerry} from "./interfaces/iberry.sol";
import {ICaveland} from "./interfaces/icaveland.sol";

struct stake {
    uint128 tokenId;
    uint64 initialStakedTs;
    uint64 lastClaimTs;
}

struct config { 
    uint32 maxLevel;
    uint32 ticketPrice;
    uint32 levelUpPrice;
    uint32 baseEmission;
    uint32 claimComission;
    uint32 additionalEmissionPerLevel;
}

contract BerryJuicer is FxBaseChildTunnel, SecuredBase {
    // Events
    event Bound(address indexed bounder, uint[] _id);
    event Unbound(address indexed bounder, uint[] _id);
    event TicketsBought(address indexed wallet, uint indexed count);
    event WinnersAnnounced(uint indexed pool, address[] winners, uint[] amounts, uint consolationPrize);
    event TicketSaleStatusChanged(bool isActive);
    event LevelUp(uint indexed tokenId, uint currentLevel);
    event Deposit(address indexed wallet, uint amount);
    event Claim(address indexed wallet, uint amount);

    // Errors
    error NotTokenOwner(uint tokenId);
    error ExceedMaxLevel(uint tokenId);
    error TicketSaleDisabled();
    error NotEnoughBalance();
    error WrongAmount();
    error AlreadyBound();
    error NotAnOwner();
    error WrongArrayLength();
    error MaxNumberAttached();
    error AnnouncerOnly();
    error EmergencyOnly();
    error NothingToClaim();

    // Bridge commands
    bytes32 public constant BOUND = keccak256("BOUND");
    bytes32 public constant UNBOUND = keccak256("UNBOUND");

    // Interfaces
    ICaveland cavelandContract;
    IBerry berryContract;

    address public announcerAddress;
    address public emergencyAddress;
    
    // Statistics
    mapping(address => uint) public walletToBerriesSpent;
    mapping(address => uint) public walletToTicketsBough;
    mapping(uint => uint) internal totalEarnedByToken;
    mapping(address => uint) internal walletToEarned;

    uint public totalBerriesSpent;
    uint public uniqueStakers;
    uint public ticketsBoughTotal;
    uint public totalBerriesWon;
    uint public winnersAllTime;

    // Configuration variables
    config public _config;

    bool public ticketSaleAllowed;

    // Bonds mappings
    mapping(address => stake[]) walletToStakes; // wallet address to stake info
    mapping(uint => address) idToStaker;        // tentacular id to staker wallet address
    mapping(uint => uint) idToWalletIndex;      // tentacular id to index in walletToStakes mapping
    mapping(uint => uint) idToCaveland;         // tentacular id to caveland attached
    mapping(uint => uint) cavelandAttachedNum;  // caveland id to amount of tokens attached

    mapping(address => uint) walletToBalance;           // wallet address to balance
    mapping(uint => uint) tokenIdToLevelAdjustment;     // tentacular id to level adjustment
    mapping(uint => uint) tokenIdToConsolationClaimed;  // tentacular id to consolation claimed
    mapping(uint => uint) cavelandIdToMultiplier;       // caveland id to multiplier

    // trackers
    uint consolationPrizeAccumulative;          // consolation prize per tentacular token
    uint public boundTotal;                     // amount of tokens bound total

    constructor(
        address _fxChild
    ) FxBaseChildTunnel(_fxChild) {
        // caveland tokens IDs starts with 1, 0 used as default multiplier
        cavelandIdToMultiplier[0] = 100;

        _config = config(   
                            10, //maxLevel
                            5,  //ticketPrice
                            5,  //levelUpPrice
                            10, //baseEmission
                            0,  //claimComission
                            5   //additionalEmissionPerLevel
                        );
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// PLAYER ACTIONS
    ////////////////////////////////////////////////////////////////////////////////

    /**
    @dev Level up token increasing it's emmission
    @param tokenId Token ID to level up
    */
    function levelUp(uint tokenId, uint levelsToAdd) external noContracts {
        if (idToStaker[tokenId] != msg.sender) revert NotTokenOwner(tokenId);
        if (tokenIdToLevelAdjustment[tokenId] + levelsToAdd > _config.maxLevel) revert ExceedMaxLevel(tokenId);

        tokenIdToLevelAdjustment[tokenId] += levelsToAdd;
        _spendFromTotalBalance(msg.sender, _config.levelUpPrice*levelsToAdd*(1 ether));

        emit LevelUp(tokenId, tokenIdToLevelAdjustment[tokenId]);
    }

    /**
    @dev Buy tickets with $BY from virtual balance will use balance only by default, claim $BY available from staking if redeemClaimable flag set to true
    @param amount Amount of tokens to purchase
    */
    function buyTickets(uint amount) external onlyTicketSaleAllowed noContracts {
        if ((amount <= 0) || (amount > 1000)) revert WrongAmount();

        ticketsBoughTotal += amount;
        walletToTicketsBough[msg.sender] += amount;

        _spendFromTotalBalance(msg.sender, amount*_config.ticketPrice*(1 ether));

        emit TicketsBought(msg.sender, amount);
    }

    /** 
    @dev deposit amount of $BY from wallet to balance
    @param amount amount of $BY to deposit
    */
    function deposit(uint amount) external noContracts {
        walletToBalance[msg.sender]+=amount;
        berryContract.burnFromWallet(msg.sender, amount);

        emit Deposit(msg.sender, amount);
    }

    /**
    @dev Claim all available tokens from balance and staking and mint $BY to caller's wallet
    */
    function claim() external noContracts {
        uint total = walletToBalance[msg.sender] + _getAvailableByWalletAndReset(msg.sender);
        if (total==0) revert NothingToClaim();

        walletToBalance[msg.sender] = 0;

        total=total*(100-_config.claimComission)/100;
        berryContract.mint(msg.sender, total);

        emit Claim(msg.sender, total);
    }

    /** 
    @dev set specified caveland as multiplier for tokens
    @param tentacularIds array of tentacular tokens to add multiplier
    @param cavelandId caveland Id which will be used as multiplier
    */
    //TODO: switch
    //TODO: set all addresses check!! 
    function attachToCaveland(uint[] calldata tentacularIds, uint cavelandId) external noContracts {
        if (cavelandId > 0) {
            if (cavelandContract.ownerOf(cavelandId) != msg.sender) revert NotTokenOwner(cavelandId);
            if (cavelandAttachedNum[cavelandId] + tentacularIds.length > 2) revert MaxNumberAttached();

            cavelandAttachedNum[cavelandId] += tentacularIds.length;
            cavelandIdToMultiplier[cavelandId] = cavelandContract.getMultiplier(cavelandId);
        } 
    
        for (uint i;i<tentacularIds.length;) {
            if (idToStaker[tentacularIds[i]]!=msg.sender) revert NotTokenOwner(tentacularIds[i]);

            // move all not claimed berries to the wallet's balance
            walletToBalance[msg.sender] += _getAvailableByTokenAndReset(tentacularIds[i]);

            uint currentCavelandId = idToCaveland[tentacularIds[i]];
            if (currentCavelandId > 0) {
                --cavelandAttachedNum[currentCavelandId];
            }
            idToCaveland[tentacularIds[i]]=cavelandId;
            unchecked { ++i;}
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// OWNER ONLY AND ADDRESS RESTRICTED
    ////////////////////////////////////////////////////////////////////////////////

    /** 
    @dev set config values
    @param newConfig config in format:
    [
        maxLevel,
        ticketPrice,
        levelUpPrice,
        baseEmission,
        claimComission,
        additionalEmissionPerLevel
    ]
    */
    function setConfig(config calldata newConfig) external onlyOwner {
        _config = newConfig;
    }

    /** 
    @dev Set announcer address which can pass the onlyAnnouncer modifier
    @param announcer announcer address
    */
    function setAnnouncerAddress(address announcer) external onlyOwner {
        announcerAddress = announcer;
    }

    /** 
    @dev Set emergency address which can pass the onlyEmergency modifier
    @param emergency emergency address
    */
    function setEmergencyAddress(address emergency) external onlyOwner {
        emergencyAddress = emergency;
    }

    function setBerryAddress(address reward) external onlyOwner {
        berryContract=IBerry(reward);
    }

    function setCavelandAddress(address multiplier) external onlyOwner {
        cavelandContract=ICaveland(multiplier);
    }

    /**
    @dev Set ticket sale status
    @param status true if sale is active or false if not
    */
    function setTicketSale(bool status) external onlyOwner {
        ticketSaleAllowed=status;

        emit TicketSaleStatusChanged(status);
    }

    /**
    @dev Announce winners and distribute amounts between them
    @param pool Pool ID to be ditributed
    @param winners Winners address array. 
    */
    function announceWinners(uint pool, address[] calldata winners, uint[] calldata amounts, uint consolationPrize) external onlyAnnouncer {
        if (winners.length != amounts.length) revert WrongArrayLength();

        winnersAllTime += winners.length;
        for (uint i;i<winners.length;) {
            walletToBalance[winners[i]] += amounts[i];
            walletToEarned[winners[i]] += amounts[i];
            totalBerriesWon += amounts[i];
            unchecked { ++i; }
        }
        consolationPrizeAccumulative += consolationPrize/boundTotal;

        emit WinnersAnnounced(pool, winners, amounts, consolationPrize);
    }

    /** 
    @dev can be used to unbound token without bridge if something will go wrong
    @param wallet wallet to unbound tokens from
    @param tokenIds tokens to unbound
    */
    function forceUnbound(address wallet, uint[] calldata tokenIds) external onlyEmergency {
        _unbound(abi.encode(wallet, tokenIds));
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// INTERNAL & UTILITY
    ////////////////////////////////////////////////////////////////////////////////

    /**
    @dev Unpack the stake data and unbound corresponded tokens
    @param stakeData data with staker ID and tokens IDs array
    */
    function _unbound(bytes memory stakeData) internal {
        (address staker, uint256[] memory tokenIds) = abi.decode(
            stakeData,
            (address, uint256[])
        );

        for (uint i;i<tokenIds.length;) {
            if (idToStaker[tokenIds[i]] != staker) revert NotAnOwner();

            _removeToken(staker, tokenIds[i]);
            unchecked { ++i; }
        }

        boundTotal-=tokenIds.length;

        if (walletToStakes[staker].length==0) {
            uniqueStakers--;
        }

        emit Unbound(staker, tokenIds);
    }

    /**
    @dev Unpack the stake data and bound correspondend tokens
    @param stakeData data with staker ID and tokens IDs array
    */
    function _bound(bytes memory stakeData) internal {
        (address staker, uint256[] memory tokenIds) = abi.decode(
            stakeData,
            (address, uint256[])
        );

        if (walletToStakes[staker].length==0) {
            uniqueStakers++;
        }

        for (uint i;i<tokenIds.length;) {
            if (idToStaker[tokenIds[i]]!=address(0)) {
                revert AlreadyBound();
            }

            _addToken(staker, uint128(tokenIds[i]));
            unchecked { ++i; }
        }

        boundTotal += tokenIds.length;

        emit Bound(staker, tokenIds);
    }

    /**
    @dev Reduce the wallet's balance for specified amount, claim staking rewards if redeemClaimable flag is true
    @param wallet Address to spend balance
    @param amount Amount of $BY to spend
    */
    function _spendFromTotalBalance(address wallet, uint amount) internal {
        walletToBalance[wallet] += _getAvailableByWalletAndReset(wallet);
        if (walletToBalance[wallet] < amount) revert NotEnoughBalance();

        totalBerriesSpent += amount;
        walletToBerriesSpent[wallet] += amount;
        walletToBalance[wallet]-=amount;
    }

    /** 
    @dev returns the amount accumulated from bonds for token and reset it
    @param tokenId token to calculate and reset
    */
    function _getAvailableByTokenAndReset(uint tokenId) internal returns(uint) {
        uint index = idToWalletIndex[tokenId];
        address stakerWallet = idToStaker[tokenId];
        stake storage _stake = walletToStakes[stakerWallet][index];

        uint earned = _getAvailableByStake(_stake);
        _resetAvailableByStake(_stake);

        walletToEarned[stakerWallet] += earned;
        totalEarnedByToken[tokenId] += earned;
        return earned;
    }

    function getTotalEarnedByToken(uint tokenId) external view returns(uint){
        uint index = idToWalletIndex[tokenId];
        address stakerWallet = idToStaker[tokenId];

        if (stakerWallet==address(0)) return 0;
        return totalEarnedByToken[tokenId] + _getAvailableByStake(walletToStakes[stakerWallet][index]);
    }

    /** 
    @dev returns the amount accumulated from bonds for wallet and reset it
    @param wallet wallet to calculate and reset
    */
    function _getAvailableByWalletAndReset(address wallet) internal returns(uint) {
        stake[] storage walletStakes = walletToStakes[wallet];
        uint claimable;
        uint earned;
        for (uint i;i<walletStakes.length;i++) {
            earned=_getAvailableByStake(walletStakes[i]);

            claimable+=earned;

            _resetAvailableByStake(walletStakes[i]);
            totalEarnedByToken[walletStakes[i].tokenId] += earned;
        }
        walletToEarned[wallet] += claimable;
        return claimable;
    }

    /** 
    @dev returns the amount accumulated from bonds for stake
    @param _stake stake to calculate
    */
    function _getAvailableByStake(stake storage _stake) internal view returns(uint) {
            uint tokenId=_stake.tokenId;
            if (block.timestamp <= _stake.lastClaimTs) { return 0; }
            uint available  =   (consolationPrizeAccumulative - tokenIdToConsolationClaimed[tokenId])+                                          //unclaimed consolation prize
                                (block.timestamp-_stake.lastClaimTs)*                                                                        //time in days since stake or last withdraw
                                (_config.baseEmission + tokenIdToLevelAdjustment[tokenId]*_config.additionalEmissionPerLevel)*                  //base emission + level increase
                                (cavelandIdToMultiplier[idToCaveland[tokenId]])*                                                            //caveland multiplier
                                (1 ether)/86400/100;    
            return available;
    }


    /** 
    @dev reset amount accumulated from bonds for specific stake
    @param _stake stake to reset
    */
    function _resetAvailableByStake(stake storage _stake) internal {
            _stake.lastClaimTs=uint64(block.timestamp);
            tokenIdToConsolationClaimed[_stake.tokenId]=consolationPrizeAccumulative;
    }

    /**
    @dev Add token information to stake
    @param wallet Staker address
    @param tokenId Token Id to be added
    */
    function _addToken(address wallet, uint128 tokenId) internal {
        idToStaker[tokenId]=wallet;
        idToWalletIndex[tokenId]=walletToStakes[wallet].length;
        walletToStakes[wallet].push(stake(tokenId, uint64(block.timestamp), uint64(block.timestamp)));
    }

    /**
    @dev Remove token information from stake
    @param wallet Staker address
    @param tokenId Token Id to be removed
    */
    function _removeToken(address wallet, uint tokenId) internal {
        uint index = idToWalletIndex[tokenId];
        stake storage _stake = walletToStakes[wallet][index];

        // Move all not claimed tokens to wallet's balance for specified token
        walletToBalance[wallet] += _getAvailableByStake(_stake);
        _resetAvailableByStake(_stake);
        totalEarnedByToken[tokenId] = 0;
        // Detach token from caveland if attached
        uint currentCavelandId = idToCaveland[tokenId];
        if (currentCavelandId > 0) {
            --cavelandAttachedNum[currentCavelandId];
            idToCaveland[tokenId]=0;
        }
        
        // Delete stake information
        stake memory lastStake = walletToStakes[wallet][walletToStakes[wallet].length-1];
        walletToStakes[wallet][index]=lastStake;
        idToWalletIndex[lastStake.tokenId]=index;
        walletToStakes[wallet].pop();
        idToStaker[tokenId]=address(0);
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// EXTERNAL VIEWER FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////////

    /**
    @dev Return staker address for specified token
    @param tokenId Token Id to get staker wallet
    */
    function getStaker(uint tokenId) external view returns(address) {
        return idToStaker[tokenId];
    }

    function getStakedByWallet(address wallet) external view returns(uint128[2][] memory) {
        stake[] storage stakes = walletToStakes[wallet];
        uint128[2][] memory tokenIds = new uint128[2][](stakes.length);
        for (uint i;i<stakes.length;) {
            tokenIds[i]=[stakes[i].tokenId, stakes[i].initialStakedTs];
            unchecked { ++i; }
        }
        return tokenIds;
    }

    /**
    @dev Return current level adjustment for token
    @param tokenId Token ID to get info
    */
    function getLevel(uint tokenId) external view returns(uint) {
        return tokenIdToLevelAdjustment[tokenId];
    }

    /**
    @dev Get total amount of berries on balance that can be claimed to wallet
    @param wallet Wallet to check
    */
    function getClaimable(address wallet) external view returns(uint) {
        stake[] storage walletStakes = walletToStakes[wallet];
        uint claimable;
        for (uint i;i<walletStakes.length;i++) {
            claimable+=_getAvailableByStake(walletStakes[i]);
        }
        return walletToBalance[wallet] + claimable;
    }

    function getLevelUpPrice() external view returns(uint) {
        return _config.levelUpPrice;
    }

    function getTicketPrice() external view returns(uint) {
        return _config.ticketPrice;
    }

    function getTotalEarned(address wallet) external view returns(uint) {
        stake[] storage walletStakes = walletToStakes[wallet];
        uint claimable;
        for (uint i;i<walletStakes.length;i++) {
            claimable+=_getAvailableByStake(walletStakes[i]);
        }
        return walletToEarned[wallet] + claimable;
    }

    /**
    @dev Get daily emission number for specified token Id
    @param tokenId Token Id to get emission
    */
    function getDailyEmissionOfToken(uint tokenId) external view returns (uint) {
        return _config.baseEmission + (tokenIdToLevelAdjustment[tokenId]*_config.additionalEmissionPerLevel);
    }

    /**
    @dev Get daily emission number for specified wallet
    @param wallet Wallet to get total emission
    */
    function getDailyEmissionOfWallet(address wallet) external view returns (uint) {
        uint totalEmission = walletToStakes[wallet].length*_config.baseEmission;
        for (uint i;i<walletToStakes[wallet].length;) {
            totalEmission += (tokenIdToLevelAdjustment[walletToStakes[wallet][i].tokenId]*_config.additionalEmissionPerLevel);
            unchecked { ++i; }
        }
        return totalEmission;
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// BRIDGING
    ////////////////////////////////////////////////////////////////////////////////

    function sendMessageToRoot(bytes memory message) internal {
        //_sendMessageToRoot(message);
        // Not used
    }

    function _processMessageFromRoot(
        uint256,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        (bytes32 cmdType, bytes memory cmdData) = abi.decode(data, (bytes32, bytes));

        if (cmdType == BOUND) {
            _bound(cmdData);
        } else if (cmdType == UNBOUND) {
            _unbound(cmdData);
        }
        else {
            revert("FxERC20ChildTunnel: INVALID_CMD");
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// MODIFIERS
    ////////////////////////////////////////////////////////////////////////////////
    
    modifier onlyTicketSaleAllowed() {
        if (ticketSaleAllowed==false) revert TicketSaleDisabled();
        _;
    }

    modifier onlyAnnouncer() {
        if (msg.sender!=announcerAddress) revert AnnouncerOnly();
        _;
    }

    modifier onlyEmergency() {
        if (msg.sender!=emergencyAddress) revert EmergencyOnly();
        _;
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// OVERRIDES
    ////////////////////////////////////////////////////////////////////////////////

    function setFxRootTunnel(address _fxRootTunnel) external virtual override onlyOwner {
        fxRootTunnel = _fxRootTunnel;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract SecuredBase {
    address public owner;

    error NoContractsAllowed();
    error NotContractOwner();
    
    constructor() { 
        owner=msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner=newOwner;
    }

    modifier onlyOwner() {
        if (msg.sender!=owner) revert NotContractOwner();
        _;
    }

    modifier noContracts() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        if ((msg.sender != tx.origin) || (size != 0)) revert NoContractsAllowed();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IBerry {
    function mint(address wallet, uint amount) external;
    function burnFromWallet(address wallet, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ICaveland {
    function getMultiplier(uint tokenId) external view returns (uint);
    function ownerOf(uint tokenId) external view returns (address);
}