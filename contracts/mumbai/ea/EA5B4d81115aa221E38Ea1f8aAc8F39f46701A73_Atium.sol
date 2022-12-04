// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Array {
    function removeElement(uint256[] storage _array, uint256 _element) internal {
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AtiumPlan.sol";
import "./Array.sol";

error Atium_NotAmount();
error Atium_SavingsGoal_Not_Hit();
error Atium_NoWithdrawal();
error Atium_TransactionFailed();
error Atium_Cancelled();
error Atium_SavingsGoal_Exceeded(uint256 goal, uint256 rem);

contract Atium is AtiumPlan {
    using Counters for Counters.Counter;
    using Array for uint256[];

    mapping(uint256 => bool) private savingsCancelled;
    mapping(uint256 => bool) private allowanceCancelled;
    mapping(uint256 => bool) private trustfundCancelled;
    mapping(uint256 => bool) private giftCancelled;

    mapping(uint256 => uint256) private allowanceBalance;
    mapping(uint256 => uint256) private trustfundBalance;


    ///////////////////////////////////////////////////////
    ///////////////// DEPOSIT FUNCTIONS ///////////////////
    ///////////////////////////////////////////////////////

    function save(uint256 _id) external payable inSavings(_id) {
        if (_id == 0 || msg.value == 0) {
            revert Atium_ZeroInput();
        }
        
        if (msg.value + savingsById[_id].amount > savingsById[_id].goal) {
            revert Atium_SavingsGoal_Exceeded({
                goal: savingsById[_id].goal,
                rem: savingsById[_id].goal - savingsById[_id].amount
            });
        }
 
        savingsById[_id].amount += msg.value;


        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function allowance(uint256 _id) external payable inAllowance(_id) {
        if (_id == 0 || msg.value == 0) {
            revert Atium_ZeroInput();
        }

        allowanceDate[_id] = allowanceById[_id].startDate;
        allowanceById[_id].deposit += msg.value;
        allowanceBalance[_id] += msg.value;

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function trustfund(uint256 _id) external payable inTrustfund(_id) {
        if (_id == 0 || msg.value == 0) {
            revert Atium_ZeroInput();
        }

        trustfundDate[_id] = trustfundById[_id].startDate;
        trustfundById[_id].amount += msg.value;
        trustfundBalance[_id] += msg.value;

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function gift(uint256 _id) external payable inGift(_id) {
        if (_id == 0 || msg.value == 0) {
            revert Atium_ZeroInput();
        }

        giftById[_id].amount += msg.value;

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }


    ///////////////////////////////////////////////////////////
    //////////// (RECEIVER) WITHDRAWAL FUNCTIONS //////////////
    ///////////////////////////////////////////////////////////

    function w_save(uint256 _id) external {
        if (savingsById[_id].amount < savingsById[_id].goal || block.timestamp < savingsById[_id].time) {
            revert Atium_SavingsGoal_Not_Hit();
        }
        if (savingsCancelled[_id]) {
            revert Atium_Cancelled();
        }
        userS_Ids[savingsById[_id].user].removeElement(_id);
        savingsCancelled[_id] = true;

        (bool sent, ) = payable(savingsById[_id].user).call{value: savingsById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function w_allowance(uint256 _id) internal {
        uint256 witAmount;

        uint256 a = block.timestamp;
        uint256 b = allowanceDate[_id];
        uint256 c = allowanceById[_id].withdrawalInterval;

        uint256 d = ((a - b) / c) + 1;
        allowanceDate[_id] += (d * c);
        
        if (allowanceBalance[_id] < allowanceById[_id].withdrawalAmount) {
            witAmount = allowanceBalance[_id];
        }

        if (allowanceBalance[_id] >= allowanceById[_id].withdrawalAmount) {
            witAmount = d * allowanceById[_id].withdrawalAmount;

            if (witAmount > allowanceBalance[_id])
            witAmount = allowanceBalance[_id];
        }

        allowanceBalance[_id] -= witAmount;

        (bool sent, ) = payable(allowanceById[_id].receiver).call{value: witAmount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function w_trustfund(uint256 _id) internal {
        uint256 witAmount;

        uint256 a = trustfundById[_id].startDate;
        uint256 b = trustfundDate[_id];
        uint256 c = trustfundById[_id].withdrawalInterval;

        uint256 d = ((a - b) / c) + 1;
        trustfundDate[_id] += (d * c);

        if (trustfundBalance[_id] < trustfundById[_id].withdrawalAmount) {
            witAmount = trustfundBalance[_id];
        }

        if (trustfundBalance[_id] >= trustfundById[_id].withdrawalAmount) {
            witAmount = d * trustfundById[_id].withdrawalAmount;

            if (witAmount > trustfundBalance[_id])
            witAmount = trustfundBalance[_id];
        }

        trustfundBalance[_id] -= witAmount;
        (bool sent, ) = payable(trustfundById[_id].receiver).call{value: witAmount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function w_gift(uint256 _id) internal {
        userG_Ids[giftById[_id].sender].removeElement(_id);

        giftCancelled[_id] = true;  

        (bool sent, ) = payable(giftById[_id].receiver).call{value: giftById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }


    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    ///////////// W I T H D R A W A L    C A L L S    F O R   C H A I N L I N K /////////////
    ///////////////////////////////  A U T O M A T I O N  ///////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function allowanceWithdraw() external {
        for (uint256 i = 1; i <= _allowanceId.current(); i++)
        if (allowanceBalance[i] > 0)
        if (block.timestamp >= allowanceDate[i])
        w_allowance(i);
    }

    function trustfundWithdraw() external {
        for (uint256 i = 1; i <= _trustfundId.current(); i++)
        if (trustfundBalance[i] > 0)
        if (block.timestamp >= trustfundDate[i])
        w_trustfund(i);
    }

    function giftWithdraw() external {
        for (uint256 i = 1; i <= _giftId.current(); i++) 
        if (block.timestamp >= giftById[i].date)
        w_gift(i);
            
    }


    ///////////////////////////////////////////////////////////
    ///////////////// CANCEL PLANS FUNCTIONS //////////////////
    ///////////////////////////////////////////////////////////

    function cancelSavings(uint256 _id) external inSavings(_id) {
        if (savingsCancelled[_id]) {
            revert Atium_Cancelled();
        }
        userS_Ids[msg.sender].removeElement(_id);

        savingsCancelled[_id] = true;
        ///addrToActiveAllowance[msg.sender].remove(_id);

        (bool sent, ) = payable(msg.sender).call{value: savingsById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function cancelAllowance(uint256 _id) external inAllowance(_id) {
        if (allowanceCancelled[_id]) {
            revert Atium_Cancelled();
        }
        userA_Ids[msg.sender].removeElement(_id);

        allowanceCancelled[_id] = true;
        
        (bool sent, ) = payable(msg.sender).call{value: allowanceBalance[_id]}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }
    }

    function cancelTrustfund(uint256 _id) external inTrustfund(_id) {
        if (trustfundCancelled[_id]) {
            revert Atium_Cancelled();
        }
        userT_Ids[msg.sender].removeElement(_id);

        trustfundCancelled[_id] = true;   
        
        (bool sent, ) = payable(msg.sender).call{value: trustfundBalance[_id]}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }    
    }

    function cancelGift(uint256 _id) external inGift(_id) {
        if (giftCancelled[_id]) {
            revert Atium_Cancelled();
        }
        userG_Ids[msg.sender].removeElement(_id);

        giftCancelled[_id] = true; 
        
        (bool sent, ) = payable(msg.sender).call{value: giftById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }     
    }
    
    ///////////////////////////////////////////////////////
    ///////////////// GETTERS FUNCTIONS  //////////////////
    ///////////////////////////////////////////////////////

    function getSavingsBalance(uint256 _id) public view returns (uint256) {
        return savingsById[_id].amount;
    }

    function getAllowanceBalance(uint256 _id) public view returns (uint256) {
        return allowanceBalance[_id];
    }

    function getTrustfundBalance(uint256 _id) public view returns (uint256) {
        return trustfundBalance[_id];
    }

    function getGiftBalance(uint256 _id) public view returns (uint256) {
        return giftById[_id].amount;     
    }

    receive() payable external {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";

error Atium_NotOwnerId();
error Atium_ZeroInput();

contract AtiumPlan {
    using Counters for Counters.Counter;

    Counters.Counter private _atiumId;
    Counters.Counter private _savingsId;
    Counters.Counter internal _allowanceId;
    Counters.Counter internal _trustfundId;
    Counters.Counter internal _giftId;

    

    mapping(uint256 => AtiumList) internal atiumById;
    mapping(uint256 => SavingsList) internal savingsById;
    mapping(uint256 => AllowanceList) internal allowanceById;
    mapping(uint256 => TrustFundList) internal trustfundById;
    mapping(uint256 => GiftList) internal giftById;

    mapping(address => uint256[]) internal userS_Ids;
    mapping(address => uint256[]) internal userA_Ids;
    mapping(address => uint256[]) internal userT_Ids;
    mapping(address => uint256[]) internal userG_Ids;

    mapping(address => uint256[]) internal receiverA_Ids;
    mapping(address => uint256[]) internal receiverT_Ids;
    mapping(address => uint256[]) internal receiverG_Ids;


    mapping(uint256 => uint256) internal allowanceDate;
    mapping(uint256 => uint256) internal trustfundDate;

    enum Select {SAVINGS, ALLOWANCE, TRUSTFUND, GIFT}
    //SAVINGS = 0, ALLOWANCE = 1, TRUSTFUND = 2. GIFT = 3

    struct AtiumList {
        uint256 id;
        address user;
        Select select;
    }

    struct SavingsList {
        uint256 id;
        address user;
        uint256 amount;
        uint256 goal;
        uint256 time;
    }

    struct AllowanceList {
        uint256 id;
        address sender;
        address receiver;
        uint256 deposit;
        uint256 startDate;
        uint256 withdrawalAmount;
        uint256 withdrawalInterval;
    }

    struct TrustFundList {
        uint256 id;
        address sender;
        address receiver;
        uint256 amount;
        uint256 startDate;
        uint256 withdrawalAmount;
        uint256 withdrawalInterval;
    }

    struct GiftList {
        uint256 id;
        address sender;
        address receiver;
        uint256 date;
        uint256 amount;
    }

    /////////////////////////////////////////////////////////
    /////////////////  ATIUM PLANS FUNCTIONS  ///////////////
    /////////////////////////////////////////////////////////

    function savingsPlanGoal(uint256 _goal) external {
        if (_goal == 0) {
            revert Atium_ZeroInput();
        }
        _atiumId.increment();
        _savingsId.increment();

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.SAVINGS
        });

        SavingsList memory s = SavingsList ({
            id: _savingsId.current(),
            user: msg.sender,
            amount: savingsById[_savingsId.current()].amount,
            goal: _goal,
            time: 0
        });

        atiumById[_atiumId.current()] = a;
        savingsById[_savingsId.current()] = s;
        userS_Ids[msg.sender].push(_savingsId.current());
    }

    function savingsPlanTime(uint256 _time) external {
        if (_time == 0) {
            revert Atium_ZeroInput();
        }
        _atiumId.increment();
        _savingsId.increment();
        _time;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.SAVINGS
        });

        SavingsList memory s = SavingsList ({
            id: _savingsId.current(),
            user: msg.sender,
            amount: savingsById[_savingsId.current()].amount,
            goal: 0,
            time: _time
        });

        atiumById[_atiumId.current()] = a;
        savingsById[_savingsId.current()] = s;
        userS_Ids[msg.sender].push(_savingsId.current());
    }

    function allowancePlan(
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external {
        
        if (_receiver == address(0) || _startDate == 0 || _amount == 0 || _interval == 0) {
            revert Atium_ZeroInput();
        }

        _atiumId.increment();
        _allowanceId.increment();
        _startDate;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.ALLOWANCE
        });

        AllowanceList memory al = AllowanceList ({
            id: _allowanceId.current(),
            sender: msg.sender,
            receiver: _receiver,
            deposit: allowanceById[_allowanceId.current()].deposit,
            startDate: _startDate,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        atiumById[_atiumId.current()] = a;
        allowanceById[_allowanceId.current()] = al;
        allowanceDate[_allowanceId.current()] = _startDate;
        userA_Ids[msg.sender].push(_allowanceId.current());
        receiverA_Ids[_receiver].push(_allowanceId.current());
    }

    function trustfundPlan(
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external {

        if (_receiver == address(0) || _startDate == 0 || _amount == 0 || _interval == 0) {
            revert Atium_ZeroInput();
        }

        _atiumId.increment();
        _trustfundId.increment();
        _startDate;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.TRUSTFUND
        });

        TrustFundList memory t = TrustFundList ({
            id: _trustfundId.current(),
            sender: msg.sender,
            receiver: _receiver,
            amount: trustfundById[_trustfundId.current()].amount,
            startDate: _startDate,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        atiumById[_atiumId.current()] = a;
        trustfundById[_trustfundId.current()] = t;
        trustfundDate[_trustfundId.current()] = _startDate;
        userT_Ids[msg.sender].push(_trustfundId.current());
        receiverT_Ids[_receiver].push(_trustfundId.current());
    }

    function giftPlan(address _receiver, uint256 _date) external {

        if (_receiver == address(0) || _date == 0) {
            revert Atium_ZeroInput();
        }

        _atiumId.increment();
        _giftId.increment();
        _date;

        AtiumList memory a = AtiumList ({
            id: _atiumId.current(),
            user: msg.sender,
            select: Select.GIFT
        });

        GiftList memory g = GiftList ({
            id: _giftId.current(),
            sender: msg.sender,
            receiver: _receiver,
            amount: giftById[_giftId.current()].amount,
            date: _date
        });

        atiumById[_atiumId.current()] = a;
        giftById[_giftId.current()] = g;
        userG_Ids[msg.sender].push(_giftId.current());
        receiverG_Ids[_receiver].push(_giftId.current());
    }



    /////////////////////////////////////////////////////
    ///////////////  GETTER FUNCTIONS ///////////////////
    /////////////////////////////////////////////////////

    function getAtium(uint256 _id) public view returns (AtiumList memory) {
        return atiumById[_id];
    }

    function getSavings(uint256 _id) public view returns (SavingsList memory) {
        return savingsById[_id];
    }

    function getAllowance(uint256 _id) public view returns (AllowanceList memory) {
        return allowanceById[_id];
    }

    function getTrustfund(uint256 _id) public view returns (TrustFundList memory) {
        return trustfundById[_id];
    }

    function getGift(uint256 _id) public view returns (GiftList memory) {
        return giftById[_id];
    }

    ///@notice - Get all active user savings
    function getAllActiveSavings(address _user) external view returns (SavingsList[] memory) {
        uint256[] memory allActiveSavings = userS_Ids[_user];
        uint256 length = allActiveSavings.length;
        SavingsList[] memory allSavings = new SavingsList[](length);

        for (uint i = 0; i < length; ) {
            allSavings[i] = savingsById[allActiveSavings[i]];
            unchecked {
                ++i;
            }
        }

        return allSavings;
    }

    function getAllActiveAllowance(address _user) external view returns (AllowanceList[] memory) {
        uint256[] memory allActiveAllowance = userA_Ids[_user];
        uint256 length = allActiveAllowance.length;
        AllowanceList[] memory allAllowance = new AllowanceList[](length);

        for (uint i = 0; i < length; ) {
            allAllowance[i] = allowanceById[allActiveAllowance[i]];
            unchecked {
                ++i;
            }
        }

        return allAllowance;
    }

    function getAllActiveTrustfund(address _user) external view returns (TrustFundList[] memory) {
        uint256[] memory allActiveTrustfund = userT_Ids[_user];
        uint256 length = allActiveTrustfund.length;
        TrustFundList[] memory allTrustfund = new TrustFundList[](length);

        for (uint i = 0; i < length; ) {
            allTrustfund[i] = trustfundById[allActiveTrustfund[i]];
            unchecked {
                ++i;
            }
        }

        return allTrustfund;
    }

    function getAllActiveGift(address _user) external view returns (GiftList[] memory) {
        uint256[] memory allActiveGift = userG_Ids[_user];
        uint256 length = allActiveGift.length;
        GiftList[] memory allGift = new GiftList[](length);

        for (uint i = 0; i < length; ) {
            allGift[i] = giftById[allActiveGift[i]];
            unchecked {
                ++i;
            }
        }

        return allGift;
    }

    ////////////////////////////////////////////////////
    ///////////////////  MODIFIERS  ////////////////////
    ////////////////////////////////////////////////////

    modifier inSavings(uint256 _id) {
        if (savingsById[_id].user != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }

    modifier inAllowance(uint256 _id) {
        if (allowanceById[_id].sender != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }

    modifier inTrustfund(uint256 _id) {
        if (trustfundById[_id].sender != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }

    modifier inGift(uint256 _id) {
        if (giftById[_id].sender != msg.sender) {
            revert Atium_NotOwnerId();
        }
        _;
    }
}