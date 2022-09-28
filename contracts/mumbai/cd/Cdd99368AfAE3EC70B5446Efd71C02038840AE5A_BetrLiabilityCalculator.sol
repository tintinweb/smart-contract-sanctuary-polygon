// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBetrData.sol";
import "./interfaces/IBetrLiabilityCalculator.sol";

contract BetrLiabilityCalculator is Ownable, IBetrLiabilityCalculator  {
 
    IBetrData public dataContract; 
  	 
	constructor(address _dataContract) {
        dataContract = IBetrData(_dataContract);
    }

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

	// Constants for p1 parameter array index
	uint8 constant LAY_MARKET_ID_i 						= 0;
	uint8 constant SELECTION_ID_i 						= 1;
	uint8 constant ODDS_i 								= 2;

	// Constants for vars variable array index
	uint8 constant RISK_i 								= 0;	
	uint8 constant BIGGEST_EXPOSURE_i 					= 0; // Reused for different function
	uint8 constant NEW_EXPOSURE_i 						= 1;
	uint8 constant PREVIOUS_ESCROW_OF_LAY_MARKET_ID_i	= 2;
	uint8 constant SECOND_BIGGEST_EXPOSURE_i 			= 3; // For Double Liability
 		
    function computeRisk(
	
		uint64[3]	calldata	_p1,				// layMarketId, selectionId, Odds
		uint256 				_stakeAmount,
		uint8 					_liabilityCalc,
		uint256					_revShareAmount		// Affiliate Rev Share Amount for this new bet - this needs to be kept in mapping and reserved in Layer Escrow for this Lay Makrket
	
	) accessAllowed external returns(uint256 r1, uint256 r2) {
		
		// Update Rev Share Amount of Lay Market
		if (_revShareAmount > 0) {			
			dataContract.addToRevShareOfLayMarketId(_p1[LAY_MARKET_ID_i], _revShareAmount);
		}
		
		// Helper Variables
		uint256[4] memory 	vars;	
		uint256 			i;
		
		// No Market Level Liability Calculation
		if (_liabilityCalc == 0) {

			vars[PREVIOUS_ESCROW_OF_LAY_MARKET_ID_i] = dataContract.escrowOfLayMarketId(_p1[LAY_MARKET_ID_i]); // Save current escrow amount
			vars[RISK_i] = _stakeAmount * _p1[ODDS_i] / 100000000 - _stakeAmount;
			vars[NEW_EXPOSURE_i] = vars[PREVIOUS_ESCROW_OF_LAY_MARKET_ID_i] + vars[RISK_i];
		
			// Set the escrow'd amount plus new risk from this bet			
			dataContract.setEscrowOfLayMarketId(_p1[LAY_MARKET_ID_i], vars[NEW_EXPOSURE_i] + _revShareAmount);

			// DEPOSIT the new risk plus the rev share amount for this bet.
			return (vars[RISK_i] + _revShareAmount, 0);		//==> EXIT HERE	
		}

		// Liability Calculation
		if (_liabilityCalc == 1 || _liabilityCalc == 2) {
		
			vars[BIGGEST_EXPOSURE_i] = 0;
			vars[NEW_EXPOSURE_i] = 0;
			vars[PREVIOUS_ESCROW_OF_LAY_MARKET_ID_i] = dataContract.escrowOfLayMarketId(_p1[LAY_MARKET_ID_i]); // Save current escrow amount - this includes previous rev share amounts
			
			// Add to selections for this new bet if not already there
			if (!dataContract.hasSelectionOfLayMarketId(_p1[LAY_MARKET_ID_i], _p1[SELECTION_ID_i])) {
				dataContract.pushToSelectionsOfLayMarketId(_p1[LAY_MARKET_ID_i], _p1[SELECTION_ID_i]);
				dataContract.setHasSelectionOfLayMarketId(_p1[LAY_MARKET_ID_i], _p1[SELECTION_ID_i], true);
			}

			// Add risk (stake * odds) of this new bet to exposure of lay market
			dataContract.addToExposureOfSelectionOfLayMarketId(_p1[LAY_MARKET_ID_i], _p1[SELECTION_ID_i], _stakeAmount * _p1[ODDS_i] / 100000000);

			// Add stake to stake total of lay market
			dataContract.addToStakeOfLayMarketId(_p1[LAY_MARKET_ID_i], _stakeAmount);
		}
		
		// Only for Normal Liability
		if (_liabilityCalc == 1) {
			
			// Find the biggest exposure
			for (i = 0; i < dataContract.selectionsOfLayMarketIdCount(_p1[LAY_MARKET_ID_i]); i++ ) {
	 
				if (dataContract.exposureOfSelectionOfLayMarketId(_p1[LAY_MARKET_ID_i], dataContract.selectionsOfLayMarketId(_p1[LAY_MARKET_ID_i], i)) > vars[BIGGEST_EXPOSURE_i]) {
					vars[BIGGEST_EXPOSURE_i] = dataContract.exposureOfSelectionOfLayMarketId(_p1[LAY_MARKET_ID_i], dataContract.selectionsOfLayMarketId(_p1[LAY_MARKET_ID_i], i));
				}
			}
			
			// Compare the biggest exposure to the stake held for this market
			if( vars[BIGGEST_EXPOSURE_i] > dataContract.stakeOfLayMarketId(_p1[LAY_MARKET_ID_i])) {
				
				vars[NEW_EXPOSURE_i] = vars[BIGGEST_EXPOSURE_i] - dataContract.stakeOfLayMarketId(_p1[LAY_MARKET_ID_i]);
			
			} else {
				
				vars[NEW_EXPOSURE_i] = 0;
			}
		}
		
		// For Double Liability
		if (_liabilityCalc == 2) {
					
			// Find the top 2 biggest exposures
			for (i = 0; i < dataContract.selectionsOfLayMarketIdCount(_p1[LAY_MARKET_ID_i]); i++ ) {
	 
				// If bigger than the biggest, then make 2nd biggest = old biggest and replace biggest with exposure
				if (dataContract.exposureOfSelectionOfLayMarketId(_p1[LAY_MARKET_ID_i], dataContract.selectionsOfLayMarketId(_p1[LAY_MARKET_ID_i], i)) > vars[BIGGEST_EXPOSURE_i]) {
					
					vars[SECOND_BIGGEST_EXPOSURE_i] = vars[BIGGEST_EXPOSURE_i];
					vars[BIGGEST_EXPOSURE_i] = dataContract.exposureOfSelectionOfLayMarketId(_p1[LAY_MARKET_ID_i], dataContract.selectionsOfLayMarketId(_p1[LAY_MARKET_ID_i], i));
				
				} else if (dataContract.exposureOfSelectionOfLayMarketId(_p1[LAY_MARKET_ID_i], dataContract.selectionsOfLayMarketId(_p1[LAY_MARKET_ID_i], i)) > vars[SECOND_BIGGEST_EXPOSURE_i]) {
					
					vars[SECOND_BIGGEST_EXPOSURE_i] = dataContract.exposureOfSelectionOfLayMarketId(_p1[LAY_MARKET_ID_i], dataContract.selectionsOfLayMarketId(_p1[LAY_MARKET_ID_i], i));					
				}	 
			}
			
			// Compare the biggest exposure + 2nd biggest exposure to the stake held for this market
			if((vars[BIGGEST_EXPOSURE_i] + vars[SECOND_BIGGEST_EXPOSURE_i]) > dataContract.stakeOfLayMarketId(_p1[LAY_MARKET_ID_i])) {
				
				vars[NEW_EXPOSURE_i] = vars[BIGGEST_EXPOSURE_i] + vars[SECOND_BIGGEST_EXPOSURE_i] - dataContract.stakeOfLayMarketId(_p1[LAY_MARKET_ID_i]);
			
			} else {
				
				vars[NEW_EXPOSURE_i] = 0;
			}
		}
			
		// Finish off	
		if (_liabilityCalc == 1 || _liabilityCalc == 2) {
			
			// Set the escrow'd amount for this market - including the rev share amount for this lay market
			dataContract.setEscrowOfLayMarketId(_p1[LAY_MARKET_ID_i], vars[NEW_EXPOSURE_i] + dataContract.revShareOfLayMarketId(_p1[LAY_MARKET_ID_i]));

			// Return with amount to withdraw or to deposit
			if (vars[PREVIOUS_ESCROW_OF_LAY_MARKET_ID_i] > vars[NEW_EXPOSURE_i] + dataContract.revShareOfLayMarketId(_p1[LAY_MARKET_ID_i])) {
				
				// WITHDRAW
				return (0, vars[PREVIOUS_ESCROW_OF_LAY_MARKET_ID_i] - vars[NEW_EXPOSURE_i] - dataContract.revShareOfLayMarketId(_p1[LAY_MARKET_ID_i]));
			
			} else {
			
				// DEPOSIT
				return (vars[NEW_EXPOSURE_i] + dataContract.revShareOfLayMarketId(_p1[LAY_MARKET_ID_i]) - vars[PREVIOUS_ESCROW_OF_LAY_MARKET_ID_i], 0);
			}
		}
    }	
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IBetrLiabilityCalculator {
    event AccessGranted(address _addr, uint256 _timestamp);
    event AccessRemoved(address _addr, uint256 _timestamp);

    // function dataContract() external view returns (address);

    function granted(address) external view returns (bool);

    function allowAccess(address _addr) external;

    function removeAccess(address _addr) external;

    function computeRisk(
        uint64[3] memory _p1,
        uint256 _stakeAmount,
        uint8 _liabilityCalc,
        uint256 _revShareAmount
    ) external returns (uint256 r1, uint256 r2);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IBetrData {
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