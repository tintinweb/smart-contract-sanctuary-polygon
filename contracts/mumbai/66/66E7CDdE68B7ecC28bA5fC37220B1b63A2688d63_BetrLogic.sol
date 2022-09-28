// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IBetrData.sol";
import "./interfaces/IXFUNEscrow.sol";
import "./interfaces/IBetrLiabilityCalculator.sol";
import "./interfaces/IBetrRevShares.sol";


contract BetrLogic is Ownable {

   	using SafeMath for uint256;
    using SafeMath for uint64;

  // Constructor function
    constructor() {
	}

	address _trustedForwarder;

    function isTrustedForwarder(address forwarder) view public returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal override view returns (address signer) {
        signer = msg.sender;
        if (msg.data.length>=20 && isTrustedForwarder(signer)) {
            assembly {
                signer := shr(96,calldataload(sub(calldatasize(),20)))
            }
        }    
    }

	function setTrustedForwarder(address _forwarder) external onlyOwner() {		
		_trustedForwarder = _forwarder;
	}

   	IBetrData public dataContract; 
    IXFUNEscrow public escrowContract;
    IBetrLiabilityCalculator public liabilityContract;
	IBetrRevShares public revSharesContract;

	// Events
    event BetPlaced(uint256 _betId);
    event BetConfirmed(uint256 _betId);
    event BetResulted(uint256 _betId, uint256 _bettorReward);
    event BetRejected(uint256 _betId);
    event BetCanceled(uint256 _betId);
	event FeeUpdated(uint8 _feeIndex, uint256 _feeAmount);
    event AccessGranted(address _addr, uint256 _timestamp);
    event AccessRemoved(address _addr, uint256 _timestamp);
	
	function setContractAddresses(

		address 				_dataContract, 
		address 				_escrowContract, 
		address 				_liabilityContract, 
		address 				_revSharesContract 
	
	) external onlyOwner {

		dataContract 		= IBetrData(_dataContract);
        escrowContract 		= IXFUNEscrow(_escrowContract);
        liabilityContract 	= IBetrLiabilityCalculator(_liabilityContract);
		revSharesContract 	= IBetrRevShares(_revSharesContract);
   }
  
	// Fees
	uint256[10] fees;
	
 	// Constants for fees array
	uint8 constant LIABILITY_CALC_REQUIRES_WITHDRAW_FEE_i		= 0;   
	uint8 constant REJECT_BY_LAYER_RETURN_FEE_i					= 1;   
	uint8 constant BETTOR_WIN_FEE_i 							= 2;   
	uint8 constant BETTOR_REFUND_FEE_i 							= 3;   
	uint8 constant BETTOR_LOST_PUSH_FEE_i 						= 4;   
	uint8 constant BETTOR_WIN_PUSH_FEE_i 						= 5;   
	uint8 constant LAYER_ESCROW_RETURN_FEE_i 					= 6;   
	uint8 constant CANCEL_BET_BY_BETTOR_RETURN_FEE_i 			= 7;   
	
	// Constants for BetData structure f64 array
	uint8 constant LAY_MARKET_ID_i 						= 0;
	uint8 constant SELECTION_ID_i 						= 1;
	uint8 constant ODDS_i 								= 2;
	uint8 constant DATETIME_CONFIRMED_i 				= 3;
	uint8 constant DATETIME_PLACED_i					= 4;
	uint8 constant DATETIME_RESULTED_i 					= 5;
	
	// For the placeBet _P3 array
	uint8 constant p3_LAYER_ADDRESS_i 				= 0;
	uint8 constant p3_RESULTOR_ADDRESS_i 			= 1;

	// For the Bet Data fa array
	uint8 constant LAYER_ADDRESS_i 				= 0;
	uint8 constant BETTOR_ADDRESS_i 			= 1;
	uint8 constant RESULTOR_ADDRESS_i 			= 2;
	
	// For Bet Data f8
	uint8 constant BET_STATUS_i 				= 0;
	uint8 constant LIABILITY_CALC_i 			= 1;
	uint8 constant WIN_OVERRIDE_REASON_CODE_i 	= 2;

	// For the _winOverride parameter array 
	uint8 constant WIN_OVERRIDE_REDUCE_ODDS_i 	= 0;
	uint8 constant WIN_OVERRIDE_REDUCE_STAKE_i 	= 1;

	// For Helper vars256 array
	uint8 constant STAKE_AMOUNT_REMAINING		= 0;			
	uint8 constant AFFILIATE_REVENUE			= 1;			
	uint8 constant NEW_STAKE_AMOUNT 			= 2;			
	uint8 constant NEW_ODDS_AMOUNT 				= 3;			
	uint8 constant WIN_AMOUNT 					= 4;
	uint8 constant PUSH_AMOUNT 					= 5;
	uint8 constant PUSH_AMOUNT_REMAINING 		= 6;
	uint8 constant GSP_REVENUE			 		= 7;



	// PLACE A NEW BET
    function placeBet(
        uint256 						_stakeAmount,		// Stake Amount
		uint64[3]			calldata	_p2,				// LAYMARKET_ID [0], selectionId [1], odds [2]
        address payable[2]	calldata	_p3,				// layerAddress, _resultorAddress
        uint8 							_liabilityCalc		// Liabiltiy Calc
									 
	) external {

		// Added this next line - not sure why it wasnt there before
		require(_stakeAmount > 0, "Stake Amount must be greater than 0");
		
		require (!dataContract.isLockedLayMarketId(_p2[LAY_MARKET_ID_i]), "Market is LOCKED!"); // Market must be open and resulting not started

        uint256 betId = dataContract.updateBetBettor(
			_stakeAmount,																			// Stake Amount
			[_p2[LAY_MARKET_ID_i], _p2[SELECTION_ID_i], _p2[ODDS_i], uint64(block.timestamp)],		// LayMarketId, selectionId, odds, datetime placed
			[_p3[p3_LAYER_ADDRESS_i], payable(_msgSender()), _p3[p3_RESULTOR_ADDRESS_i]],				// Addresses: Layer, Bettor, Resultor 	
			_liabilityCalc 																			// Liability Calc
         ); 
         
		escrowContract.deposit(_msgSender() , _stakeAmount);
        
		dataContract.addToTotalBetsOfLayMarketId(_p2[LAY_MARKET_ID_i], 1);
        
		emit BetPlaced(betId);
    }
	
	

	// CONFIRM BET
    function confirmBet(
		uint256 _betId, 
		uint8 	_betStatus
	
	) external {

        require(_betStatus >= 1 && _betStatus <= 9, "Invalid Bet Status");
		
		// Get Bet Return variables
		uint256						stakeAmount;	// Stake Amount (decimal 18)
		uint64[8] 			memory	f64;			// LAYMARKET_ID[0], selectionId[1], Odds (decimal 8)[2], DateTimes: Placed[3], Confirmed[4], Resulted[5], Win Override Reduce Odds % (decimal 8)[6], Win Override Reduce Stake % (decimal 8)[7]
		address payable[3]  memory	fa; 			// Addresses: Layer, Bettor, Resultor                  
		uint8[3] 			memory 	f8;  			// betStatus; liabilityCalc, wORC – Win Override Reason Code
		         
		// ====> Get the Bet
        (stakeAmount, f64, fa, f8) = dataContract.getBet(_betId);

 		// sender must be layer and status must be 0
		require(_msgSender()  == fa[LAYER_ADDRESS_i] && f8[BET_STATUS_i] == 0, "Invalid _msgSender");

      	// betStatus is what the caller wants the new betStatus to be... 
		// betStatus = 1 - Confirm Bet

       	// The Ketchup incident Bet 2150 5th Oct. Cannot confirm if market locked, must refund
	   	uint8 betStatus = _betStatus;
        if (betStatus == 1 && dataContract.isLockedLayMarketId(f64[LAY_MARKET_ID_i])) {
            //Trying to confirm bet, but laymarket is locked. Must not confirm, just cancel by system
            betStatus = 3;
        }

		if (betStatus == 1) {

			uint256 toDeposit;
			uint256 toWithdraw;
			uint256 revShareAmount;
            
			// Update Bet			
			require(dataContract.updateBetLayer(_betId, betStatus, _msgSender() , uint64(block.timestamp)) == true);
			
			// Work out Liability
			// Rev Share is paid on Layer Profit. Need to calculate and store the Rev Share commitment 
			
			// If Layers are paying Affiliates then check if Bettor belongs to an Affiliate and if so get the total amount that needs to be paid to affiliate if necessary
			if (revSharesContract.layerAffiliatePercent() > 0) {
				
				if (revSharesContract.getBettorAffiliateTotalPercent(fa[BETTOR_ADDRESS_i]) == 10000000000) { // Total Affilate rev share amount must add up to 100%. Is 0 if no affilieate belongs to bettor 

					revShareAmount = revSharesContract.layerAffiliatePercent().mul(stakeAmount).div(10000000000);	
				}
			}
			 
			// GSP Rev Share to be put aside too
			if(revSharesContract.getResultorGSPPercent(fa[RESULTOR_ADDRESS_i]) > 0) {
				
				revShareAmount = revShareAmount.add(revSharesContract.getResultorGSPPercent(fa[RESULTOR_ADDRESS_i]).mul(stakeAmount).div(10000000000));
			}
			
			// Calculate Liability
			(toDeposit, toWithdraw) = liabilityContract.computeRisk([f64[LAY_MARKET_ID_i], f64[SELECTION_ID_i], f64[ODDS_i]], stakeAmount, f8[LIABILITY_CALC_i], revShareAmount);
            
			// Make escrow deposit if liability greater than current escrow or withdraw if less
			if (toDeposit > 0 && toWithdraw == 0) {
                
				escrowContract.deposit(_msgSender() , toDeposit);
            
			} else if (toWithdraw > 0 && toDeposit == 0) {
                
				escrowContract.withdraw(_msgSender() , toWithdraw, returnFee(toWithdraw, fees[LIABILITY_CALC_REQUIRES_WITHDRAW_FEE_i]));
            }
            
			emit BetConfirmed(_betId);
        
		} else {
            
			// Reject and Refund this bet
			require(dataContract.updateBetLayer(_betId, betStatus, _msgSender() , uint64(block.timestamp)) == true);
            
			bettorWithdraw(fa[BETTOR_ADDRESS_i], stakeAmount, returnFee(stakeAmount, fees[REJECT_BY_LAYER_RETURN_FEE_i]));
            
			dataContract.subtractFromTotalBetsOfLayMarketId(f64[LAY_MARKET_ID_i], 1);
            
			emit BetRejected(_betId);
        }		
	}

	// RESULT BET
    function resultBet(	
		uint256 				_betId, 
		uint8 					_selectionResult, 
		uint64[2]	calldata 	_winOverride, 			//[0] = % to reduce odds by (decimal 8), [1] reduce stake by % (decimal 8)
		uint8 					_winOverrideReasonCode	// 0 = no reduce, 1 = Rule 4, 2 = Dead Heat, 3 = Rule 4 and Dead Heat
	
	) external returns(bool) {

        require(_selectionResult >= 12 && _selectionResult <= 16, "Invalid _selectionResult");  

		// Return variables
		uint256						stakeAmount;	// Stake Amount (decimal 18)
		uint64[8] 			memory	f64;			// LAYMARKET_ID[0], selectionId[1], Odds (decimal 8)[2], DateTimes: Placed[3], Confirmed[4], Resulted[5], Win Override Reduce Odds % (decimal 8)[6], Win Override Reduce Stake % (decimal 8)[7]
		address payable[3] 	memory	fa; 			// Addresses: Layer, Bettor, Resultor                  
		uint8[3] 			memory 	f8;  			// betStatus; liabilityCalc, wORC – Win Override Reason Code
		
 		// ====> Get the Bet
        (stakeAmount, f64, fa, f8) = dataContract.getBet(_betId);				

        // Check Bet Status and _msgSender()  are correct
        require(f8[BET_STATUS_i] == 1 && fa[RESULTOR_ADDRESS_i] == _msgSender() , "Invalid _msgSender!!");
        
        // If this is the first bet to be resulted, then lock market so no more bets can be accepted
        if (dataContract.resultedBetsOfLayMarketId(f64[LAY_MARKET_ID_i]) == 0) {
            dataContract.lockLayMarketId(f64[LAY_MARKET_ID_i]);
        }

        // Update Bet with new Status
        require(dataContract.updateBetResultor(_betId, _selectionResult, _msgSender() , uint64(block.timestamp), _winOverride, _winOverrideReasonCode));

		// Set up VARS256[]
		uint256[10] memory vars256; 
		
		// Setup Index i for structs
		uint256 i;
				
        // Bettor LOSS
        if (_selectionResult == 12) {
						
			vars256[STAKE_AMOUNT_REMAINING] = stakeAmount;

			// GSP Rev Share
			if(revSharesContract.getResultorGSPPercent(fa[RESULTOR_ADDRESS_i]) > 0) {
				
				vars256[GSP_REVENUE] = revSharesContract.getResultorGSPPercent(fa[RESULTOR_ADDRESS_i]).mul(stakeAmount).div(10000000000);

				escrowContract.moveEscrowShadow(fa[BETTOR_ADDRESS_i], revSharesContract.getResultorGSPRevSharePool(fa[RESULTOR_ADDRESS_i]), vars256[GSP_REVENUE]); 
				escrowContract.withdraw(revSharesContract.getResultorGSPRevSharePool(fa[RESULTOR_ADDRESS_i]), vars256[GSP_REVENUE], 0); 
				
				vars256[STAKE_AMOUNT_REMAINING] = vars256[STAKE_AMOUNT_REMAINING].sub(vars256[GSP_REVENUE]);
				
			}
			
			// Affiliate(s) Rev Share
			if (revSharesContract.layerAffiliatePercent() > 0) {
				 
				if (revSharesContract.getBettorAffiliateTotalPercent(fa[BETTOR_ADDRESS_i]) == 10000000000) { // Total Affilate rev share amount must add up to 100% 

	// Maybe check if bettor_address is the EOSBet Contract -this means its an EOS Bet
	// If so, then look up the ultimate affilate address and use that for payment
				
					for (i = 0; i < revSharesContract.getBettorAffiliateLength(fa[BETTOR_ADDRESS_i]); i++) {
						
						//	Calculate Affiliate Revenue Share Amount
						vars256[AFFILIATE_REVENUE] = revSharesContract.layerAffiliatePercent().mul(revSharesContract.getBettorAffiliatePercent(fa[BETTOR_ADDRESS_i], i)).mul(stakeAmount).div(10000000000).div(10000000000);

						//	Pay Affiliate from Stake - move escrow from bettor to affiliate, then withdraw
						escrowContract.moveEscrowShadow(fa[BETTOR_ADDRESS_i], revSharesContract.getBettorAffiliateRevSharePool(fa[BETTOR_ADDRESS_i], i), vars256[AFFILIATE_REVENUE]); 
						escrowContract.withdraw(revSharesContract.getBettorAffiliateRevSharePool(fa[BETTOR_ADDRESS_i], i), vars256[AFFILIATE_REVENUE], 0); 

						dataContract.subtractFromRevShareOfLayMarketId(f64[LAY_MARKET_ID_i], vars256[AFFILIATE_REVENUE]);	
						
						vars256[STAKE_AMOUNT_REMAINING] = vars256[STAKE_AMOUNT_REMAINING].sub(vars256[AFFILIATE_REVENUE]);						
					}
				}
			}				
			
            escrowContract.moveEscrowShadow(fa[BETTOR_ADDRESS_i], fa[LAYER_ADDRESS_i], vars256[STAKE_AMOUNT_REMAINING]); // Move Stake from Bettor to Layer
            
			dataContract.setEscrowOfLayMarketId(f64[LAY_MARKET_ID_i], dataContract.escrowOfLayMarketId(f64[LAY_MARKET_ID_i]).add(vars256[STAKE_AMOUNT_REMAINING])); // Add Stake to Accumulator
			
			dataContract.addToProfitOfLayMarketId(f64[LAY_MARKET_ID_i], int256(vars256[STAKE_AMOUNT_REMAINING])); // Add Stake Amount of this Bet to Profit of this Lay Market
            
			emit BetResulted(_betId, 0); // Event
        }

        // Bettor WIN
        if (_selectionResult == 13) {
			
			require(_winOverride[WIN_OVERRIDE_REDUCE_ODDS_i] < 10000000000 && _winOverride[WIN_OVERRIDE_REDUCE_STAKE_i] < 10000000000, "Invalid _winOverride"); // Both must be less that 100%
									
			// Reduce odds by winOverride amounts for rule 4 and rule 10 stuff
			if (_winOverride[WIN_OVERRIDE_REDUCE_ODDS_i] > 0) {
				vars256[NEW_ODDS_AMOUNT] = f64[ODDS_i].sub(100000000).mul(10000000000 - _winOverride[WIN_OVERRIDE_REDUCE_ODDS_i]).div(10000000000).add(100000000); // Odds reduced
			} else {				
				vars256[NEW_ODDS_AMOUNT] = f64[ODDS_i]; // Odds the same
			}
			
			// Reduce stake by winOverride amounts for rule 4 and rule 10 stuff
			if (_winOverride[WIN_OVERRIDE_REDUCE_STAKE_i] > 0) {
				vars256[NEW_STAKE_AMOUNT] = stakeAmount.mul(10000000000 - _winOverride[WIN_OVERRIDE_REDUCE_STAKE_i]).div(10000000000);  
			} else {
				vars256[NEW_STAKE_AMOUNT] = stakeAmount;			
			}
			
			// win amount calculation now includes stake amount as it can now be below the value of stake amount (rule 10)
			vars256[WIN_AMOUNT] = vars256[NEW_STAKE_AMOUNT].mul(vars256[NEW_ODDS_AMOUNT]).div(100000000); // Replaces Risk Amount. Win amount is stake * odds\			

			// If the case is that the win is less than the stake, then return the win to bettor but send remainder of stake - win to layer
			if (vars256[WIN_AMOUNT] <= stakeAmount) {
				
				escrowContract.moveEscrowShadow(fa[BETTOR_ADDRESS_i], fa[LAYER_ADDRESS_i], stakeAmount.sub(vars256[WIN_AMOUNT])); // Move remainder of Stake from Bettor to Layer           
				
				dataContract.setEscrowOfLayMarketId(f64[LAY_MARKET_ID_i], dataContract.escrowOfLayMarketId(f64[LAY_MARKET_ID_i]).add(stakeAmount.sub(vars256[WIN_AMOUNT]))); // Add remainder of Stake to Accumulator
				
				dataContract.addToProfitOfLayMarketId(f64[LAY_MARKET_ID_i], int256(stakeAmount.sub(vars256[WIN_AMOUNT]))); // Add Stake - Win as Profit of this Lay Market
				
			} else {

				escrowContract.moveEscrowShadow(fa[LAYER_ADDRESS_i], fa[BETTOR_ADDRESS_i], vars256[WIN_AMOUNT].sub(stakeAmount)); // Move Win Amount (less stake) from Layer to Bettor
				
				dataContract.setEscrowOfLayMarketId(f64[LAY_MARKET_ID_i], dataContract.escrowOfLayMarketId(f64[LAY_MARKET_ID_i]).sub(vars256[WIN_AMOUNT].sub(stakeAmount))); // Subtract Win from Accumulator

				dataContract.addToProfitOfLayMarketId(f64[LAY_MARKET_ID_i], int256(vars256[WIN_AMOUNT].sub(stakeAmount)) * -1); // Add Win - Stake as Loss of this Bet to Lay Market
			}

			// Withdraw WIN_AMOUNT to Bettor
			bettorWithdraw(fa[BETTOR_ADDRESS_i], vars256[WIN_AMOUNT], returnFee(vars256[WIN_AMOUNT], fees[BETTOR_WIN_FEE_i]));
			
            emit BetResulted(_betId, vars256[WIN_AMOUNT]);  // Event
        }

        // REFUND
        if (_selectionResult == 14) {
			
			bettorWithdraw(fa[BETTOR_ADDRESS_i], stakeAmount, returnFee(stakeAmount, fees[BETTOR_REFUND_FEE_i]));
  
			emit BetResulted(_betId, stakeAmount);  // Event
        }

        // Bettor LOSE / PUSH
        if (_selectionResult == 15) {
			
			vars256[PUSH_AMOUNT] = stakeAmount.div(2);  // Calculate the Win for the Layer which is half the bettors Stake

			vars256[PUSH_AMOUNT_REMAINING] = vars256[PUSH_AMOUNT];

			// Return PUSH amount to Bettor			
			bettorWithdraw(fa[BETTOR_ADDRESS_i], stakeAmount.sub(vars256[PUSH_AMOUNT]), returnFee(stakeAmount.sub(vars256[PUSH_AMOUNT] ), fees[BETTOR_LOST_PUSH_FEE_i]));

			// GSP Rev Share
			if(revSharesContract.getResultorGSPPercent(fa[RESULTOR_ADDRESS_i]) > 0) {
				
				vars256[GSP_REVENUE] = revSharesContract.getResultorGSPPercent(fa[RESULTOR_ADDRESS_i]).mul(vars256[PUSH_AMOUNT]).div(10000000000);

				escrowContract.moveEscrowShadow(fa[BETTOR_ADDRESS_i], revSharesContract.getResultorGSPRevSharePool(fa[RESULTOR_ADDRESS_i]), vars256[GSP_REVENUE]); 
				
				escrowContract.withdraw(revSharesContract.getResultorGSPRevSharePool(fa[RESULTOR_ADDRESS_i]), vars256[GSP_REVENUE], 0); 
				
				vars256[PUSH_AMOUNT_REMAINING] = vars256[PUSH_AMOUNT_REMAINING].sub(vars256[GSP_REVENUE]);
				
			}

			// If Layers are paying Affiliates
			if (revSharesContract.layerAffiliatePercent() > 0) {
			
				if (revSharesContract.getBettorAffiliateTotalPercent(fa[BETTOR_ADDRESS_i]) == 10000000000) { // Total Affilate rev share amount must add up to 100% 
					
	// Maybe check if bettor_address is the EOSBet Contract -this means its an EOS Bet
	// If so, then look up the ultimate affilate address and use that for payment
	
					for (i = 0; i < revSharesContract.getBettorAffiliateLength(fa[BETTOR_ADDRESS_i]); i++) {
						
						//	Calculate Affiliate Revenue Share Amount
						vars256[AFFILIATE_REVENUE] = revSharesContract.layerAffiliatePercent().mul(revSharesContract.getBettorAffiliatePercent(fa[BETTOR_ADDRESS_i], i)).mul(vars256[PUSH_AMOUNT]).div(10000000000).div(10000000000);
					
						//	Pay Affiliate - move escrow from bettor to affiliate, then withdraw
						escrowContract.moveEscrowShadow(fa[BETTOR_ADDRESS_i], revSharesContract.getBettorAffiliateRevSharePool(fa[BETTOR_ADDRESS_i], i), vars256[AFFILIATE_REVENUE]); 
						
						escrowContract.withdraw(revSharesContract.getBettorAffiliateRevSharePool(fa[BETTOR_ADDRESS_i], i), vars256[AFFILIATE_REVENUE], 0); 

						dataContract.subtractFromRevShareOfLayMarketId(f64[LAY_MARKET_ID_i], vars256[AFFILIATE_REVENUE]);	
										
						vars256[PUSH_AMOUNT_REMAINING] = vars256[PUSH_AMOUNT_REMAINING].sub(vars256[AFFILIATE_REVENUE]);						
					}	
				}
			}
            
			// Move PUSH_AMOUNT_REMAINING to the Layer. This is the net Profit 
			escrowContract.moveEscrowShadow(fa[BETTOR_ADDRESS_i], fa[LAYER_ADDRESS_i], vars256[PUSH_AMOUNT_REMAINING] );  

			dataContract.setEscrowOfLayMarketId(f64[LAY_MARKET_ID_i], dataContract.escrowOfLayMarketId(f64[LAY_MARKET_ID_i]).add(vars256[PUSH_AMOUNT_REMAINING] )); // Add push amount to Accumulator
 
			dataContract.addToProfitOfLayMarketId(f64[LAY_MARKET_ID_i], int256(vars256[PUSH_AMOUNT_REMAINING] )); // Add Profit of this Bet to Lay Market
 
			emit BetResulted(_betId, stakeAmount.sub(vars256[PUSH_AMOUNT] ));  //Event       
		}

        // Bettor WIN / PUSH
        if (_selectionResult == 16) {
			
			vars256[WIN_AMOUNT] = (stakeAmount.mul(f64[ODDS_i]).div(100000000).sub(stakeAmount)).div(2);  // Calculate the Bettor Win which is half of the Risk
            
			escrowContract.moveEscrowShadow(fa[LAYER_ADDRESS_i], fa[BETTOR_ADDRESS_i], vars256[WIN_AMOUNT]); // Move Half of the Risk from the Layer to the Bettor            
			
			// Withdraw stakeAmount + WIN_AMOUNT to Bettor
			bettorWithdraw(fa[BETTOR_ADDRESS_i], stakeAmount.add(vars256[WIN_AMOUNT]), returnFee(stakeAmount.add(vars256[WIN_AMOUNT]), fees[BETTOR_WIN_PUSH_FEE_i]));
            
			dataContract.setEscrowOfLayMarketId(f64[LAY_MARKET_ID_i], dataContract.escrowOfLayMarketId(f64[LAY_MARKET_ID_i]).sub(vars256[WIN_AMOUNT]));  // Subtract half the risk from the Accumulator
 
			dataContract.addToProfitOfLayMarketId(f64[LAY_MARKET_ID_i], int256(vars256[WIN_AMOUNT]) * -1); // Add Loss of this Bet to Lay Market
 
			emit BetResulted(_betId, stakeAmount.add(vars256[WIN_AMOUNT]));  // Event
        }
	
		// For ALL Results, Increase Resulted Bets counter by 1
        dataContract.addToResultedBetsOfLayMarketId(f64[LAY_MARKET_ID_i], 1);  
        
		// Last Bet to Result, return ALL contents of accumulator to Layer
        if (dataContract.totalBetsOfLayMarketId(f64[LAY_MARKET_ID_i]) == dataContract.resultedBetsOfLayMarketId(f64[LAY_MARKET_ID_i])) {
			            
			// Withdraw remainder in escrow for this lay market to Layer
			if (dataContract.escrowOfLayMarketId(f64[LAY_MARKET_ID_i]) > 0) {
                
				escrowContract.withdraw(fa[LAYER_ADDRESS_i], dataContract.escrowOfLayMarketId(f64[LAY_MARKET_ID_i]), returnFee(dataContract.escrowOfLayMarketId(f64[LAY_MARKET_ID_i]), fees[LAYER_ESCROW_RETURN_FEE_i]));  // Payout the Layer what is in the Accumulator
 
				dataContract.setEscrowOfLayMarketId(f64[LAY_MARKET_ID_i], 0); // Set the Accumulator to 0
				
				dataContract.subtractFromRevShareOfLayMarketId(f64[LAY_MARKET_ID_i], dataContract.revShareOfLayMarketId(f64[LAY_MARKET_ID_i]));	// Reset Rev Share for this Lay Market
			}
        }

		return true;
    }
	
	// CANCEL BET by bettor
    function cancelBet(uint256 _betId) external {
		uint256						stakeAmount;	// Stake Amount (decimal 18)
		uint64[8] 			memory	f64;			// LayMarketId[0], selectionId[1], Odds (decimal 8)[2], DateTimes: Placed[3], Confirmed[4], Resulted[5], Win Override Reduce Odds % (decimal 8)[6], Win Override Reduce Stake % (decimal 8)[7] 
		address payable[3] 	memory	fa; 			// Addresses: Layer, Bettor, Resultor                  
		uint8[3] 			memory 	f8;  			// betStatus; liabilityCalc, winOverrideReasonCode  
		
 		// ====> Get the Bet
        (stakeAmount, f64, fa, f8) = dataContract.getBet(_betId);				
	
        require(fa[BETTOR_ADDRESS_i] == _msgSender()  && f8[BET_STATUS_i] == 0, "Invalid _msgSender or BetStatus <> 0");

		uint256 stakeToReturn = dataContract.cancelBetBettor(_betId, _msgSender() , uint64(block.timestamp));

		bettorWithdraw(payable(_msgSender() ), stakeToReturn, returnFee(stakeToReturn, fees[CANCEL_BET_BY_BETTOR_RETURN_FEE_i]));
			    
		dataContract.subtractFromTotalBetsOfLayMarketId(f64[LAY_MARKET_ID_i], 1);
		
		emit BetCanceled(_betId);
   }
	
	function bettorWithdraw(
		address payable 	_bettorAddress,
		uint256 			_amount,
		uint256 			_fee
		
	) internal {
						
		escrowContract.withdraw(_bettorAddress, _amount, _fee);			

		return;		
	}
	
	// Set the fee value in the array. See above for constant values
    function setFeeAmount(uint8 _feeIndex, uint256 _feeAmount) external onlyOwner {
        fees[_feeIndex] = _feeAmount;
        emit FeeUpdated(_feeIndex, _feeAmount);
    }
	
	// Have to have this coz the escrow contract has underflow issue .withdraw sub fee
	function returnFee(uint256 _withdrawAmount, uint256 _feeAmount) private pure returns (uint256) {		
		if (_feeAmount > _withdrawAmount) {			
			return _withdrawAmount; // If fee is greater than the withdraw amount, then limit fee to withdraw amount			
		} else {			
			return _feeAmount;
		}		
	}

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IXFUNEscrow {
    event AccessGranted(address _addr, uint256 _id);
    event AccessRemoved(address _addr, uint256 _id);
    event EscrowMoved(address _who, address _fromAddress, uint256 _amount);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event TokenEscrowDeposit(
        address _who,
        address _fromAddress,
        uint256 _amount
    );
    event TokenEscrowWithdraw(
        address _who,
        address _toAddress,
        uint256 _amount,
        uint256 _fee
    );

    function escrowedBalancesOfService(uint256, address)
        external
        view
        returns (uint256);

    function escrowedOfService(uint256) external view returns (uint256);

    function granted(address) external view returns (uint256);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function token() external view returns (address);

    function transferOwnership(address newOwner) external;

    function allowAccess(address _addr, uint256 _id) external;

    function removeAccess(address _addr) external;

    function deposit(address _addr, uint256 _amount) external;

    function moveEscrowShadow(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function withdraw(
        address _to,
        uint256 _amount,
        uint256 _fee
    ) external;

    function escrowedBalanceOf(uint256 _id, address _address)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IBetrRevShares {
    // Rev Share Deal struct, For GSP and Affilate deals
	struct revShare {
		address 	revSharePool;  	// Where to send the revenue share amount
		uint64 		percent;		// Commission - How much to take
	}

    event NewBettorAffiliate(
        address _bettorAddress,
        uint256 _index,
        address _revSharePool,
        uint64 _percent,
        uint256 _index2
    );
    event UpdateLayerAffiliatePercent(uint64 _percent);
    event UpdateResultorGSP(
        address _resultorAddress,
        address _revSharePool,
        uint64 _percent
    );

    function layerAffiliatePercent() external view returns (uint64);

    // function tokenContract() external view returns (address);

    function updateLayerAffiliatePercent(uint64 _percent) external;

    function updateResultorGSP(
        address _resultorAddress,
        address _revSharePool,
        uint64 _percent
    ) external;

    function getResultorGSPRevSharePool(address _resultorAddress)
        external
        view
        returns (address);

    function getResultorGSPPercent(address _resultorAddress)
        external
        view
        returns (uint64);

    function newBettorAffiliate(
        address _bettorAddress,
        address _revSharePool,
        uint64 _percent
    ) external returns (uint256, uint256);

    function getRevSharePoolLength(address _revSharePool)
        external
        view
        returns (uint256);

    function getRevSharePoolBettor(address _revSharePool, uint256 _index)
        external
        view
        returns (address);

    function getBettorAffiliateLength(address _bettorAddress)
        external
        view
        returns (uint256);

    function getBettorAffiliateRevSharePool(
        address _bettorAddress,
        uint256 _index
    ) external view returns (address);

    function getBettorAffiliatePercent(address _bettorAddress, uint256 _index)
        external
        view
        returns (uint64);

    function getBettorAffiliateTotalPercent(address _bettorAddress)
        external
        view
        returns (uint64);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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