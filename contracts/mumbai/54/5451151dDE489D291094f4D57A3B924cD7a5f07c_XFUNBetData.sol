// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IXFUNBetData.sol";

contract XFUNBetData is IXFUNBetData, Ownable {
 
    /**
     * It is always set to the last internal bet id
     */
    uint256 betsCounter; 

    /**
     * This is the mapping which stores all the addresses which can call
     * functions protected with accessAllowed modifier
     */
    mapping(address => bool) public granted;

	modifier accessAllowed() {
        require(granted[msg.sender] == true);
        _;
    }

    function allowAccess(address _addr) external onlyOwner {
        granted[_addr] = true;
        emit AccessGranted(_addr, block.timestamp);
    }

    function removeAccess(address _addr) external onlyOwner {
        granted[_addr] = false;
        emit AccessRemoved(_addr, block.timestamp);
    }

	// EVENTS
    // event AccessGranted(address _addr, uint256 _timestamp);
    // event AccessRemoved(address _addr, uint256 _timestamp);

	// Bet Structure
	struct BetData {
		uint256		        stakeAmount;	// Stake Amount (decimal 18)
		uint64[8] 	        f64;			// layMarketId[0], selectionId[1], Odds (decimal 8)[2], DateTimes: Placed[3], Confirmed[4], Resulted[5], Win Override Reduce Odds % (decimal 8)[6], Win Override Reduce Stake % (decimal 8)[7]
		address payable[3] 	fa; 			// Addresses: Layer, Bettor, Resultor                  
		uint8[3] 	        f8;  			// betStatus; liabilityCalc, wORC – Win Override Reason Code
	}

    /**
     * Mapping for storing bets.
     * The lowest possible betId is 1
     */
    mapping(uint256 => BetData) public bets;

    /**
     * Total number of bets that can be resulted in a layMarketId
     */
    mapping(uint64 => uint256) public totalBetsOfLayMarketId; 

    /**
     * Total number of bets that have been already resulted in a layMarketId
     */
    mapping(uint64 => uint256) public resultedBetsOfLayMarketId; 

    /**
     * If a single bet is resulted, we lock layMarketId and we won't accept new bets
     */
    mapping(uint64 => bool) public isLockedLayMarketId; 

    /**
     * Mappings for liability calculation
     */
    mapping(uint64 => mapping(uint64 => bool)) public 		hasSelectionOfLayMarketId; 
    mapping(uint64 => uint64[]) public 						selectionsOfLayMarketId; 
    mapping(uint64 => uint256) public 						selectionsOfLayMarketIdCount; 	// Check if this can be replaced by using .length
    mapping(uint64 => mapping(uint256 => uint64)) public 	selectionsOfLayMarketIdIndex; 	// NEW! returns the Selection of the LayMarket+Index
    mapping(uint64 => mapping(uint64 => uint256)) public 	exposureOfSelectionOfLayMarketId; 	 
    mapping(uint64 => uint256) public 						escrowOfLayMarketId;
    mapping(uint64 => uint256) public 						stakeOfLayMarketId;
	mapping(uint64 => int256) public 						profitOfLayMarketId; 	// NEW note that it is an int256, -ve is loss
	mapping(uint64 => uint256) public						revShareOfLayMarketId;	// NEW for keeping track of the Rev Share Commitment amount - in Confirm Bet Liability Calc.

	

	// STATUS Codes for betStatus
    /*
     0 = Not Confirmed (Bet is created by Bettor but not (yet) Confirmed by Layer
     1 = Confirmed & Not Resulted Yet
     13 = Bettor Won
     12 = Bettor Lost
     14 = Refund
     16 = Win / Push
     15 = Lose/ Push
     2 = Bet Rejected By Layer
     3 = Bet Cancelled By System – timed out with no response from Layer for example
     4 = Cancelled by Bettor

     5,6,7,8,9 Other Bet Cancel Codes reserved
    */
 
	// Constants for BetData structure
	uint8 constant LAY_MARKET_ID_i 						= 0;
	uint8 constant SELECTION_ID_i 						= 1;
	uint8 constant ODDS_i 								= 2;
	uint8 constant DATETIME_PLACED_i					= 3;
	uint8 constant DATETIME_CONFIRMED_i 				= 4;
	uint8 constant DATETIME_RESULTED_i 					= 5;
	uint8 constant WIN_OVERRIDE_REDUCE_ODDS_i 			= 6;
	uint8 constant WIN_OVERRIDE_REDUCE_STAKE_i 			= 7;

	uint8 constant LAYER_ADDRESS_i 						= 0;
	uint8 constant BETTOR_ADDRESS_i 					= 1;
	uint8 constant RESULTOR_ADDRESS_i 					= 2;
	
	uint8 constant BET_STATUS_i 						= 0;
	uint8 constant LIABILITY_CALC_i 					= 1;
	uint8 constant WIN_OVERRIDE_REASON_CODE_i 			= 2;
	
	
	// Place Bet by Bettor - PLACE
    function updateBetBettor(
        uint256 	                    _stakeAmount,	// Stake Amount
        uint64[4]           calldata	_p2,			// layMarketId, selectionId, odds, datetime placed
		address payable[3]  calldata	_p3,			// Addresses: Layer, Bettor, Resultor 	
		uint8		                    _liabilityCalc 	// Liability Calc
	
	) public accessAllowed returns(uint256){

        betsCounter++;
        BetData storage bet = bets[betsCounter];
		
		bet.stakeAmount								= _stakeAmount;		// Stake Amount
		bet.f64[LAY_MARKET_ID_i]					= _p2[0];			// layMarketId
		bet.f64[SELECTION_ID_i]						= _p2[1];			// selectionId
		bet.f64[ODDS_i]								= _p2[2];			// odds
		bet.f64[DATETIME_PLACED_i]					= _p2[3];			// datetime placed
		bet.fa[LAYER_ADDRESS_i]						= _p3[0];			// Layer Address
		bet.fa[BETTOR_ADDRESS_i]					= _p3[1];			// Bettor Address
		bet.fa[RESULTOR_ADDRESS_i]					= _p3[2];			// Resultor Address
		bet.f8[LIABILITY_CALC_i]					= _liabilityCalc;	// Liability Calc
																		// betStatus defaults to 0 - not confirmed
        return betsCounter;
    }

	// Update bet by Layer - CONFIRM
    function updateBetLayer(
		uint256 	_betId, 
		uint8 		_betStatus, 
		address 	_sender, 
		uint64 		_timestamp
	
	) public accessAllowed returns(bool) {
		
        BetData storage bet = bets[_betId];
        require(bet.fa[LAYER_ADDRESS_i] == _sender && bet.f8[BET_STATUS_i] == 0);  // Layer Address, betStatus

        bet.f8[BET_STATUS_i] 			= _betStatus; 		// betStatus
        bet.f64[DATETIME_CONFIRMED_i] 	= _timestamp; 		// dateTime Confirmed
        
		return true;
    }

    // bet update by Resultor - RESULT
    function updateBetResultor(
		uint256 	            _betId, 
		uint8 		            _selectionResult, 
		address		            _sender, 
		uint64 		            _timestamp, 
		uint64[2]   calldata 	_winOverride, 			// Odds Reduce Percent (8 decimals), Stake Reduce Percent (8 decimals)
		uint8 		            _winOverrideReasonCode
	
	) public accessAllowed returns(bool) {
        
		BetData storage bet = bets[_betId];
        require(bet.fa[2] == _sender && bet.f8[0] == 1); // Resultor Address, Bet Status

        bet.f8[BET_STATUS_i] 					= _selectionResult; 		// Bet Status
        bet.f64[DATETIME_RESULTED_i] 			= _timestamp; 				// dateTimeResulted
		bet.f64[WIN_OVERRIDE_REDUCE_ODDS_i] 	= _winOverride[0]; 			// Reduce Odds by %
		bet.f64[WIN_OVERRIDE_REDUCE_STAKE_i] 	= _winOverride[1]; 			// Reduce Stake by %
		bet.f8[WIN_OVERRIDE_REASON_CODE_i] 		= _winOverrideReasonCode; 	// Win Overrride Reason
		
        return true;
    }

    function getBet(
        uint256 _betId
    ) external view returns(
        uint256                         stakeAmount, 
        uint64[8]           memory      f64, 
        address payable[3]  memory      fa, 
        uint8[3]            memory      f8
    ) {  
		BetData memory bet = bets[_betId];
        
		return (
			bet.stakeAmount,
			bet.f64,
			bet.fa,
			bet.f8
       );
    }
	
    // Cancel this bet - CANCEL
    function cancelBetBettor(
		uint256 _betId, 
		address _sender, 
		uint64 _timestamp
	
	) external accessAllowed returns(uint256) {
        
		BetData storage bet = bets[_betId];
        
		require(bet.fa[BETTOR_ADDRESS_i] == _sender && bet.f8[BET_STATUS_i] == 0); // address Bettor, Bet Status
        
		bet.f8[BET_STATUS_i] 			= 4; 			// Bet Status set to 4 = cancelled by bettor
        bet.f64[DATETIME_CONFIRMED_i] 	= _timestamp; 	// datetime confirmed 
        
		return bet.stakeAmount; // Returns stake amount
    }


    function addToTotalBetsOfLayMarketId(uint64 _layMarketId, uint256 _amount) external accessAllowed {
        totalBetsOfLayMarketId[_layMarketId] = totalBetsOfLayMarketId[_layMarketId] + _amount;
    }

    function subtractFromTotalBetsOfLayMarketId(uint64 _layMarketId, uint256 _amount) external accessAllowed {
        totalBetsOfLayMarketId[_layMarketId] = totalBetsOfLayMarketId[_layMarketId] - _amount;
    }

    function addToResultedBetsOfLayMarketId(uint64 _layMarketId, uint256 _amount) external accessAllowed {
        resultedBetsOfLayMarketId[_layMarketId] = resultedBetsOfLayMarketId[_layMarketId] + _amount;
    }

    function substractFromResultedBetsOfLayMarketId(uint64 _layMarketId, uint256 _amount) external accessAllowed {
        resultedBetsOfLayMarketId[_layMarketId] = resultedBetsOfLayMarketId[_layMarketId] - _amount;
    }

    function lockLayMarketId(uint64 _layMarketId) external accessAllowed {
        isLockedLayMarketId[_layMarketId] = true;
    }

    function setHasSelectionOfLayMarketId(uint64 _layMarketId, uint64 _selection, bool _choice) external accessAllowed {
        hasSelectionOfLayMarketId[_layMarketId][_selection] = _choice;
    }

    function addToExposureOfSelectionOfLayMarketId(uint64 _layMarketId, uint64 _selection, uint256 _amount) external accessAllowed {
        exposureOfSelectionOfLayMarketId[_layMarketId][_selection] = exposureOfSelectionOfLayMarketId[_layMarketId][_selection] + _amount;
    }
    function subtractFromExposureOfSelectionOfLayMarketId(uint64 _layMarketId, uint64 _selection, uint256 _amount) external accessAllowed {
        exposureOfSelectionOfLayMarketId[_layMarketId][_selection] = exposureOfSelectionOfLayMarketId[_layMarketId][_selection] - _amount;
    }

    function pushToSelectionsOfLayMarketId(uint64 _layMarketId, uint64 _selectionId)  external accessAllowed {

        require(!hasSelectionOfLayMarketId[_layMarketId][_selectionId], "Error Selection already known");
        selectionsOfLayMarketId[_layMarketId].push(_selectionId);
        selectionsOfLayMarketIdCount[_layMarketId]++;

        // New - so we can get the selection by index
        selectionsOfLayMarketIdIndex[_layMarketId][selectionsOfLayMarketIdCount[_layMarketId]] = _selectionId;  
    }

    function setEscrowOfLayMarketId(uint64 _layMarketId, uint256 _amount) external accessAllowed {
        escrowOfLayMarketId[_layMarketId] = _amount;
    }

	function addToStakeOfLayMarketId(uint64 _layMarketId, uint256 _amount) external accessAllowed {
        stakeOfLayMarketId[_layMarketId] = stakeOfLayMarketId[_layMarketId] + _amount;
    }
	function subtractFromStakeOfLayMarketId(uint64 _layMarketId, uint256 _amount) external accessAllowed {
        stakeOfLayMarketId[_layMarketId] = stakeOfLayMarketId[_layMarketId] - _amount;
    }
	
	// New function to update the profit. Amount can be -ve
	function addToProfitOfLayMarketId(uint64 _layMarketId, int256 _amount) external accessAllowed {		
		profitOfLayMarketId[_layMarketId] = profitOfLayMarketId[_layMarketId] + _amount;  // Cannot use SafeMath for int256
	}	

	// New Function to add Rev Share Commitment amount
	function addToRevShareOfLayMarketId(uint64 _layMarketId, uint256 _amount) external accessAllowed {
        revShareOfLayMarketId[_layMarketId] = revShareOfLayMarketId[_layMarketId] + _amount;
    }

	// New Function to subtract Rev Share Commitment amount
	function subtractFromRevShareOfLayMarketId(uint64 _layMarketId, uint256 _amount) external accessAllowed {
        revShareOfLayMarketId[_layMarketId] = revShareOfLayMarketId[_layMarketId] - _amount;
    }

    function getLayMarketInfo(
        uint64    _layMarketId
    )  public view returns (
        uint256[7]  memory  f256,
        bool                fb
    ) {
        f256[0]    = totalBetsOfLayMarketId[_layMarketId];
        f256[1]    = resultedBetsOfLayMarketId[_layMarketId];
        f256[2]    = selectionsOfLayMarketIdCount[_layMarketId];
        f256[3]    = escrowOfLayMarketId[_layMarketId];
        f256[4]    = stakeOfLayMarketId[_layMarketId];
        f256[5]    = uint256(profitOfLayMarketId[_layMarketId]);
        f256[6]    = revShareOfLayMarketId[_layMarketId];  
        fb         = isLockedLayMarketId[_layMarketId];
    }

    function getExposureOfSelectionOfLayMarketId(uint64 _layMarketId,  uint64 _index) public view returns (uint64 f64, uint256 f256) {
        return (selectionsOfLayMarketIdIndex[_layMarketId][_index], exposureOfSelectionOfLayMarketId[_layMarketId][selectionsOfLayMarketIdIndex[_layMarketId][_index]]);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IXFUNBetData {
    event AccessGranted(address _addr, uint256 _timestamp);
    event AccessRemoved(address _addr, uint256 _timestamp);

    function bets(uint256) external view returns (uint256 stakeAmount);

    function escrowOfLayMarketId(uint64) external view returns (uint256);

    function exposureOfSelectionOfLayMarketId(uint64, uint64)
        external
        view
        returns (uint256);

    function granted(address) external view returns (bool);

    function hasSelectionOfLayMarketId(uint64, uint64)
        external
        view
        returns (bool);

    function isLockedLayMarketId(uint64) external view returns (bool);

    function profitOfLayMarketId(uint64) external view returns (int256);

    function resultedBetsOfLayMarketId(uint64) external view returns (uint256);

    function revShareOfLayMarketId(uint64) external view returns (uint256);

    function selectionsOfLayMarketId(uint64, uint256)
        external
        view
        returns (uint64);

    function selectionsOfLayMarketIdCount(uint64)
        external
        view
        returns (uint256);

    function selectionsOfLayMarketIdIndex(uint64, uint256)
        external
        view
        returns (uint64);

    function stakeOfLayMarketId(uint64) external view returns (uint256);

    function totalBetsOfLayMarketId(uint64) external view returns (uint256);

    function allowAccess(address _addr) external;

    function removeAccess(address _addr) external;

    function updateBetBettor(
        uint256 _stakeAmount,
        uint64[4] memory _p2,
        address payable[3] calldata _p3,
        uint8 _liabilityCalc
    ) external returns (uint256);

    function updateBetLayer(
        uint256 _betId,
        uint8 _betStatus,
        address _sender,
        uint64 _timestamp
    ) external returns (bool);

    function updateBetResultor(
        uint256 _betId,
        uint8 _selectionResult,
        address _sender,
        uint64 _timestamp,
        uint64[2] memory _winOverride,
        uint8 _winOverrideReasonCode
    ) external returns (bool);

    function getBet(uint256 _betId)
        external
        view
        returns (
            uint256                         stakeAmount, 
            uint64[8]           memory      f64, 
            address payable[3]  memory      fa, 
            uint8[3]            memory      f8
        );

    function cancelBetBettor(
        uint256 _betId,
        address _sender,
        uint64 _timestamp
    ) external returns (uint256);

    function addToTotalBetsOfLayMarketId(uint64 _layMarketId, uint256 _amount)
        external;

    function subtractFromTotalBetsOfLayMarketId(
        uint64 _layMarketId,
        uint256 _amount
    ) external;

    function addToResultedBetsOfLayMarketId(
        uint64 _layMarketId,
        uint256 _amount
    ) external;

    function substractFromResultedBetsOfLayMarketId(
        uint64 _layMarketId,
        uint256 _amount
    ) external;

    function lockLayMarketId(uint64 _layMarketId) external;

    function setHasSelectionOfLayMarketId(
        uint64 _layMarketId,
        uint64 _selection,
        bool _choice
    ) external;

    function addToExposureOfSelectionOfLayMarketId(
        uint64 _layMarketId,
        uint64 _selection,
        uint256 _amount
    ) external;

    function subtractFromExposureOfSelectionOfLayMarketId(
        uint64 _layMarketId,
        uint64 _selection,
        uint256 _amount
    ) external;

    function pushToSelectionsOfLayMarketId(
        uint64 _layMarketId,
        uint64 _selectionId
    ) external;

    function setEscrowOfLayMarketId(uint64 _layMarketId, uint256 _amount)
        external;

    function addToStakeOfLayMarketId(uint64 _layMarketId, uint256 _amount)
        external;

    function subtractFromStakeOfLayMarketId(
        uint64 _layMarketId,
        uint256 _amount
    ) external;

    function addToProfitOfLayMarketId(uint64 _layMarketId, int256 _amount)
        external;

    function addToRevShareOfLayMarketId(uint64 _layMarketId, uint256 _amount)
        external;

    function subtractFromRevShareOfLayMarketId(
        uint64 _layMarketId,
        uint256 _amount
    ) external;

    function getLayMarketInfo(uint64 _layMarketId)
        external
        view
        returns (uint256[7] memory f256, bool fb);

    function getExposureOfSelectionOfLayMarketId(
        uint64 _layMarketId,
        uint64 _index
    ) external view returns (uint64 f64, uint256 f256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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