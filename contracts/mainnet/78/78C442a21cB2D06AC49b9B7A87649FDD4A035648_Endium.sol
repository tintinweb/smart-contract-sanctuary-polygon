/**
 *Submitted for verification at polygonscan.com on 2022-02-14
*/

// SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later

pragma solidity >=0.7.0 <0.9.0;

contract Endium {
    string  public name = "Endium";
    string  public symbol = "NDM";
    string  public standard = "Endium v1.0";
    uint COMMISSION_PERCENT = 1; // transaction fee set aside for redistribution
    uint8 public decimals = 18;
    uint256 public totalSupply; // total current supply
    uint256 public maxSupply= 100000000000 * (uint256(10) ** decimals); // max amount that can exists
    uint256 public initialSupply=2000000000; // how many tokens are minted at launch
    uint256 public freeClaimSupply= 3000000000 * (uint256(10) ** decimals); // the limit of many tokens that are distributed for free
    uint256 public individualFreeClaimLimit=10000; // the max limit one wallet can claim for free
    uint256 FIRST_TRANSACTION_BONUS_LIMIT = 150000 * (uint256(10) ** decimals); // limit the amount of the first transaction bonus
    uint256 FIRST_TRANSACTION_BONUS_CEILING = 4000000000 * (uint256(10) ** decimals); // when supply hits this number, stop the FTB payouts
    uint256 public mintingCost = 0.0018 ether; // cost to mint new tokens
    uint256 public sharePool; //pool of shares
    address public ORIGIN_ADDR ; // contract owner wallet address
    address[] addressStore; //array of addresses for looping
    mapping (address => bool) addedToAddressStore; // true/false if added to array
    mapping (address => bool) alreadyPaid; // mapping used during redistributions
    mapping(address => uint256) public sendCount; // counter to track transaction sends
    mapping(address => uint256) public balanceOf; // mapping of wallet balances
    mapping(address => mapping(address => uint256)) public allowance; // mapping of secondary wallet allowance when approved
    mapping(address => mapping(address => bool)) public approvedAlways; //mapping of wallets with unlimited approval until revoked
    mapping(address => mapping(address => uint256)) public secondarySenderFees; //mapping of secondary sender transaction fees
    mapping(address => uint256) public lastAwards; //mapping of the last award amount for each wallet
    mapping(address => uint256) public totalAwards; //mapping of award total for each wallet
    mapping(address => address[]) public walletAccess; //track wallet access permissions
    mapping(address => uint256) public lastSharesPaid; //time of the last share paid

    

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );


    constructor(){
        //set contract owner
        ORIGIN_ADDR = msg.sender;
        //mint initial supply
        _mint(initialSupply);
    }

    /*
    * @dev Mint initial supply
    * @param _mintAmount The amount to be minted
    */
    function _mint (uint256 _mintAmount)  public payable returns(bool _success){
        /*****************************************************************************
        * FREE CLAIM PHASE
        *****************************************************************************/
        // if msg.sender is the owner OR 
        // we are inside the free claim window, have a balance of less than 
        // individualFreeClaimLimit, AND are minting less than individualFreeClaimLimit
         if(
             msg.sender != ORIGIN_ADDR && 
             (
                balanceOf[msg.sender] > 0 ||
                _mintAmount > individualFreeClaimLimit
             )
         ){

                /*****************************************************************************
                * PURCHASE / LIQUIDITY PHASE
                *****************************************************************************/
                //require liquiditiy in exchange for miniting new tokens                
                uint256 amountToPay = mintingCost * _mintAmount;
                require(msg.value >= amountToPay,"Transfer failed. Please ensure you are sending enough value."); 
            }
        
        //make sure totalSupply is less than maxSupply 
        if( (totalSupply + _mintAmount) < maxSupply){
            //add balance to sender
            balanceOf[msg.sender] += _mintAmount * (uint256(10) ** decimals);
            //update totalSupply
            totalSupply += _mintAmount * (uint256(10) ** decimals);
            //add original address to list
             if(addedToAddressStore[msg.sender] == false){
                addressStore.push(msg.sender);
                addedToAddressStore[msg.sender] = true;
            }
        } else {
            revert();
        }

        return true;
    }

    /*
    * @dev Transfer balance from one wallet to another
    * @param _to Address of wallet to transfer to
    * @param _value amount to transfer
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //must have value
        require(_value > 0);
        //sender must have funds to send
        require(balanceOf[msg.sender] >= _value);
        
        //calc transaction fee for this transaction
        uint256 transactionFee = _value * COMMISSION_PERCENT / 100;
        //calc value to send to _to
        uint256 valueToSend = _value - transactionFee;

        /*****************************************************************************
        * FIRST TRANSACTION BONUS - Get back up to FIRST_TRANSACTION_BONUS_LIMIT (150%)
        *****************************************************************************/
        //check if we should deduct or leave balance for first transaction bonus
         if(totalSupply <= FIRST_TRANSACTION_BONUS_CEILING && sendCount[msg.sender] == 0){
                //limit the bonus to something reasonable
                uint256 transactionBounusTotal = valueToSend * 150 / 100;
                 

                  if(transactionBounusTotal > FIRST_TRANSACTION_BONUS_LIMIT){
                      // deduct the difference of the bonus ceiling and the transaction value
                      balanceOf[msg.sender] -= (_value - FIRST_TRANSACTION_BONUS_LIMIT);

                        //save last reward
                        lastAwards[msg.sender] = FIRST_TRANSACTION_BONUS_LIMIT;
                        //sum total awards
                        totalAwards[msg.sender] += FIRST_TRANSACTION_BONUS_LIMIT;
                        //mint new coint
                        totalSupply += FIRST_TRANSACTION_BONUS_LIMIT;
                        
                  } 
                  if(transactionBounusTotal < FIRST_TRANSACTION_BONUS_LIMIT){
                      //add the extra 50% to the sender balance
                      balanceOf[msg.sender] += (transactionBounusTotal - _value);

                        //save last reward
                        lastAwards[msg.sender] = (transactionBounusTotal - _value);
                        //sum total awards
                        totalAwards[msg.sender] += (transactionBounusTotal - _value);

                        //keep track of new tokens minted
                        totalSupply += transactionBounusTotal;
                  }

         } else {
              //update sender balance
             balanceOf[msg.sender] -= _value;
         }
        
        //update recipient balance
        balanceOf[_to] += valueToSend;

        //add sender to address list
        if(addedToAddressStore[msg.sender] == false){
            addressStore.push(msg.sender);
            addedToAddressStore[msg.sender] = true;
        }

        //add recipient to address list
        if(addedToAddressStore[_to] == false){
            addressStore.push(_to);
            addedToAddressStore[_to] = true;
        }

        //payout pending transaction fees participants
        payoutShares(msg.sender);
        payoutShares(_to);

        //set asise shares from this transaction
        setAsideShares(transactionFee);
        //increment send counter
        sendCount[msg.sender]++;
       

        emit Transfer(msg.sender, _to, valueToSend);

        return true;
    }



    /*
    * @dev Calculate percentage
    * @param part The numerator
    * @param whole The denominator
    */
    function getPercent(uint _part, uint _whole) private pure returns(uint percent) {
        if(_part > 0){
            uint numerator = _part * 1000;
            uint temp = numerator / _whole + 5; // proper rounding up
            return temp / 10;
        } else {
            return uint(0);
        }
    }

    /*
    * @dev Payout transaction fees to all holders
    * @param transactionFee The amount to be distributed
    */
    function setAsideShares(uint256 transactionFee) private returns (bool success){
        //update the share pool
        sharePool += transactionFee;
        return true;
    }

    /*
    * @dev Payout transaction fees to all holders
    * @param transactionFee The amount to be distributed
    */
    function payoutShares(address _shareHolder) private returns (bool success){
        
        /*****************************************************************************
        * PAYOUT SHARE
        *****************************************************************************/
       
        if(lastSharesPaid[_shareHolder] == 0 || lastSharesPaid[_shareHolder] > block.timestamp - 30 days){
            // Get wallet address
            address payThisAddress = _shareHolder;
            
            //check if this holder has already been paid
            if(alreadyPaid[payThisAddress] == false){
                //get percentage stake
                uint256 percentOfTotal = getPercent(balanceOf[payThisAddress],totalSupply);

                //calc value to pay this holder
                uint256 valueToPay = (sharePool * 50 / 100) *  percentOfTotal / 100;

                valueToPay += (sharePool * 50 / 100) / addressStore.length;

                //they must hold at least 1% to be in this pool
                if(valueToPay > 0){
                    //add to balance
                    balanceOf[payThisAddress] += valueToPay;
                    //save last reward
                    lastAwards[payThisAddress] = valueToPay;
                    //sum total awards
                    totalAwards[payThisAddress] += valueToPay;
                    //mark as paid
                    alreadyPaid[payThisAddress] = true;
                    //log last share paid
                    lastSharesPaid[_shareHolder] = block.timestamp;
                    //update share pool
                    sharePool -= valueToPay;
                } 
            
            
            }
        }
    
        return true;

    }

    /*
    * @dev Approve secondary sender to act on behalf of holder
    * @param _spender Address of secondary spender
    * @param _value The amount the secondary spender is approved to spend
    */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        //set amount secondary sender can spend
        allowance[msg.sender][_spender] = _value;
        //add to list
        walletAccess[msg.sender].push(_spender);
        //emit Approval event
        emit Approval(msg.sender, _spender, _value);

        return true;
    }


    /*
    * @dev Approve secondary sender to act on behalf of holder until revoked
    * @param _spender Address of secondary sender to approve
    * @param secondarySenderFee The percentage of the transaction the secondary sender should receive
    */
    function approveAlways(address _spender, uint256 _secondarySenderFee) public returns (bool success) {
        //set approval record for secondary sender
        approvedAlways[msg.sender][_spender] = true;

        //add to list
        walletAccess[msg.sender].push(_spender);
        
        //save fee amount
        secondarySenderFees[msg.sender][_spender] = _secondarySenderFee;
        return true;
    }

    /*
    * @dev Revoke permission for secondary sender to act on behalf of holder
    * @param _spender Address of secondary sender to revoke
    */
    function revokeApproval(address _spender) public returns (bool success) {
        //set approval record for secondary sender
        approvedAlways[msg.sender][_spender] = false;
        //reset fees
        secondarySenderFees[msg.sender][_spender] = 0;
        //remove from list
        for (uint i = 0; i < walletAccess[msg.sender].length; i++) {
            if(_spender == walletAccess[msg.sender][i]){
                delete walletAccess[msg.sender][i];
            }
        }
        return true;
    }

    /*
    * @dev Send funds as a secondary sender on behalf of another holder - requires approval via approveAlways() or approve()
    * @param _from The wallet address funds will be sent from
    * @param _to The wallet address funds will be sent to
    * @param _amount The amount to spend
    */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        //must have value
        require(_amount > 0);
        //holder must have balance
        require(_amount <= balanceOf[_from]);
        //secondary sender must be allowed to spend at least as much as this transaction costs
        require( _amount <= allowance[_from][msg.sender] || approvedAlways[_from][msg.sender] == true);

        //check if secondary sender. If so, pay transaction fee to secondary sender
        if(approvedAlways[_from][msg.sender] && secondarySenderFees[_from][msg.sender] > 0){
            //calculate this fee
            uint256 thisFee = _amount * secondarySenderFees[_from][msg.sender] / 100;
            //send see to secondary sender
            balanceOf[msg.sender] += thisFee;
            //update remaining value
            _amount = _amount - thisFee;
        }

        //calc transaction fee for this transaction
        uint256 transactionFee = _amount * COMMISSION_PERCENT / 100;
        //calc value to send to _to
        uint256 valueToSend = _amount - transactionFee;

        //update sender balance
        balanceOf[_from] -= valueToSend;
        //update recipient balance
        balanceOf[_to] += valueToSend;

        //update remaining allowance
        if(allowance[_from][msg.sender] != 0){
            allowance[_from][msg.sender] -= valueToSend;
        }

        //add sender to address list
        if(addedToAddressStore[_from] == false){
            addressStore.push(_from);
            addedToAddressStore[_from] = true;
        }

        //add recipient to address list
        if(addedToAddressStore[_to] == false){
            addressStore.push(_to);
            addedToAddressStore[_to] = true;
        }

        //payout pending transaction fees participants
        payoutShares(msg.sender);
        payoutShares(_to);

        //payout shares
        setAsideShares(transactionFee);
        //increment send counter
        sendCount[msg.sender]++;


        emit Transfer(_from, _to, valueToSend);

        return true;
    }

    /*
    * @dev Withdraw funds for liquidity pool
    */
    function withdraw() public payable{
        //must be contract owner
        require(msg.sender == ORIGIN_ADDR);
        //withdraw all liquid funds (not this contract's tokens)
        (bool os, ) = payable(ORIGIN_ADDR).call{value: address(this).balance  }("");
        require(os);
    }


    


    /*
    * @dev Get total count of wallets
    */
    function getWalletCount() public view returns(uint256 _wallets){
        return addressStore.length;
    }

    /*
    * @dev Get amount of last reward
    */
    function getLastAward(address _wallet) public view returns(uint256 _wallets){
        return lastAwards[_wallet];
    }

    /*
    * @dev Get amount of all rewards
    */
    function getTotalAwards(address _wallet) public view returns(uint256 _wallets){
        return totalAwards[_wallet];
    }

    /*
    * @dev Get minting cost
    */
    function getMintingCost() public view returns(uint256 _cost){
        return mintingCost;
    }  

    /*
    * @dev Get free claim supply 
    */
    function getFreeClaimSupply() public view returns(uint256 _cost){
        return freeClaimSupply;
    } 

    /*
    * @dev Get free claim limit 
    */
    function getFreeClaimLimit() public view returns(uint256 _cost){
        return individualFreeClaimLimit;
    }

    /*
    * @dev Get list of accounts who are approved for any amount
    */
    function getWalletAccess(address _wallet) public view returns(address[] memory _wallets){
        return walletAccess[_wallet];
    }

    /*
    * @dev Get share pool totla
    */
    function getSharePool() public view returns(uint256){
        return sharePool;
    }

}