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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./AtiumPlan.sol";

error Atium_NotAmount();
error Atium_NotReceiverId();
error Atium_SavingsGoal_Not_Hit();
error Atium_NoWithdrawal();
error Atium_TransactionFailed();
error Atium_Cancelled();
error Atium_SavingsGoal_Exceeded(uint256 goal, uint256 rem);

contract Atium is AtiumPlan {
    using Counters for Counters.Counter;
    Counters.Counter private _loyaltyId;

    mapping(uint256 => bool) private savingsCancelled;
    mapping(uint256 => bool) private allowanceCancelled;
    mapping(uint256 => bool) private trustfundCancelled;
    mapping(uint256 => bool) private giftCancelled;

    mapping(uint256 => uint256) private allowanceBalance;
    mapping(uint256 => uint256) private trustfundBalance;

    /*
    mapping(uint256 => address) private loyaltyId;
    mapping(address => uint256) private loyaltyPoints;
    */
    event Withdrawn(address indexed receiver, uint256 atium, uint256 amount);
    /// for atium values -- SAVINGS = 0, ALLOWANCE = 1, TRUSTFUND = 2. GIFT = 3


    ///////////////////////////////////////////////////////
    ///////////////// DEPOSIT FUNCTIONS ///////////////////
    ///////////////////////////////////////////////////////

    function save(uint256 _id, uint256 _amount) external payable inSavings(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }
        if (_amount + savingsById[_id].amount > savingsById[_id].goal) {
            revert Atium_SavingsGoal_Exceeded({
                goal: savingsById[_id].goal,
                rem: savingsById[_id].goal - savingsById[_id].amount
            });
        }
        /*
        _loyaltyId.increment();
        
        if (member[msg.sender] == true) {
            loyaltyId[_loyaltyId.current()] = msg.sender;
            loyaltyPoints[msg.sender]++;
        }
        */
        savingsById[_id].amount += _amount;

        SavingsList memory s = SavingsList ({
            id: _id,
            user: msg.sender,
            amount: savingsById[_id].amount,
            goal: savingsById[_id].goal,
            time: savingsById[_id].time
        });

        savingsById[_id] = s;

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Savings(
            _id, 
            msg.sender, 
            savingsById[_id].amount,
            savingsById[_id].goal, 
            savingsById[_id].time
            );
    }

    function allowance(uint256 _id, uint256 _amount) external payable inAllowance(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }
        /*
        _loyaltyId.increment();

        if (member[msg.sender] == true) {
            loyaltyId[_loyaltyId.current()] = msg.sender;
            loyaltyPoints[msg.sender]++;
        }
        */
        allowanceById[_id].deposit += _amount;
        allowanceBalance[_id] += _amount;

        AllowanceList memory al = AllowanceList ({
            id: _id,
            sender: msg.sender,
            receiver: allowanceById[_id].receiver,
            deposit: allowanceById[_id].deposit,
            startDate: allowanceById[_id].startDate,
            withdrawalAmount: allowanceById[_id].withdrawalAmount,
            withdrawalInterval: allowanceById[_id].withdrawalInterval
        });

        allowanceById[_id] = al;

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Allowance(
        _id, 
        msg.sender,
        allowanceById[_id].receiver,
        allowanceById[_id].deposit,
        allowanceById[_id].startDate,
        allowanceById[_id].withdrawalAmount,
        allowanceById[_id].withdrawalInterval
        );
    }

    function trustfund(uint256 _id, uint256 _amount) external payable inTrustfund(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }
        /*
        _loyaltyId.increment();

        if (member[msg.sender] == true) {
            loyaltyId[_loyaltyId.current()] = msg.sender;
            loyaltyPoints[msg.sender]++;
        }
        */
        trustfundById[_id].amount += _amount;
        trustfundBalance[_id] += _amount;

        TrustFundList memory t = TrustFundList ({
            id: _id,
            sender: msg.sender,
            receiver: trustfundById[_id].receiver,
            amount: trustfundById[_id].amount,
            startDate: trustfundById[_id].startDate,
            withdrawalAmount: trustfundById[_id].withdrawalAmount,
            withdrawalInterval: trustfundById[_id].withdrawalInterval
        });

        trustfundById[_id] = t;

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Trustfund(
        _id, 
        msg.sender,
        trustfundById[_id].receiver,
        trustfundById[_id].amount,
        trustfundById[_id].startDate,
        trustfundById[_id].withdrawalAmount,
        trustfundById[_id].withdrawalInterval
        );
    }

    function gift(uint256 _id, uint256 _amount) external payable inGift(_id) {
        if (_id == 0 || _amount == 0) {
            revert Atium_ZeroInput();
        }
        if (msg.value != _amount) {
            revert Atium_NotAmount();
        }
        /*
        _loyaltyId.increment();

        if (member[msg.sender] == true) {
            loyaltyId[_loyaltyId.current()] = msg.sender;
            loyaltyPoints[msg.sender]++;
        }
        */
        giftById[_id].amount += _amount;

        GiftList memory g = GiftList ({
            id: _id,
            sender: msg.sender,
            receiver: giftById[_id].receiver,
            date: giftById[_id].date,
            amount: giftById[_id].amount
        });

        giftById[_id] = g;

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Gift(
            _id, 
            msg.sender, 
            giftById[_id].receiver,
            giftById[_id].amount,
            giftById[_id].date
            );
    }


    ///////////////////////////////////////////////////////////
    //////////// (RECEIVER) WITHDRAWAL FUNCTIONS //////////////
    ///////////////////////////////////////////////////////////

    function w_save(uint256 _id) external inSavings(_id) {
        if (savingsById[_id].amount < savingsById[_id].goal || block.timestamp < savingsById[_id].time) {
            revert Atium_SavingsGoal_Not_Hit();
        }
        if (savingsCancelled[_id]) {
            revert Atium_Cancelled();
        }
        savingsCancelled[_id] = true;

        (bool sent, ) = payable(msg.sender).call{value: savingsById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 0, savingsById[_id].amount);
    }

    function w_allowance(uint256 _id) external rAllowance(_id) {
        uint256 witAmount;
        
        if (allowanceBalance[_id] == 0) {
            revert Atium_NoWithdrawal();
        }

        uint256 a = block.timestamp;
        uint256 b = allowanceDate[_id];
        uint256 c = allowanceById[_id].withdrawalInterval;

        if ((a - b) < c) {
            revert Atium_OnlyFutureDate();
        }

        uint256 d = (a - b) / c;
        allowanceDate[_id] += (d * c);
        
        if (allowanceBalance[_id] < allowanceById[_id].withdrawalAmount) {
            witAmount = allowanceBalance[_id];
        }

        if (allowanceBalance[_id] >= allowanceById[_id].withdrawalAmount) {
            witAmount = d * allowanceById[_id].withdrawalAmount;
        }

        allowanceBalance[_id] -= witAmount;
        (bool sent, ) = payable(msg.sender).call{value: witAmount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 1, witAmount);
    }

    function w_trustfund(uint256 _id) external rTrustfund(_id) {
        uint256 witAmount;

        if (trustfundBalance[_id] == 0) {
            revert Atium_NoWithdrawal();
        }

        uint256 a = trustfundById[_id].startDate;
        uint256 b = trustfundDate[_id];
        uint256 c = trustfundById[_id].withdrawalInterval;

        uint256 d = (a - b) / c;
        trustfundDate[_id] += (d * c);

        if (trustfundBalance[_id] < trustfundById[_id].withdrawalAmount) {
            witAmount = trustfundBalance[_id];
        }

        if (trustfundBalance[_id] >= trustfundById[_id].withdrawalAmount) {
            witAmount = d * trustfundById[_id].withdrawalAmount;
        }

        trustfundBalance[_id] -= witAmount;
        (bool sent, ) = payable(msg.sender).call{value: witAmount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 2, witAmount);
    }

    function w_gift(uint256 _id) external rGift(_id) {
        giftCancelled[_id] = true;
        (bool sent, ) = payable(msg.sender).call{value: giftById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 3, giftById[_id].amount);
    }


    ///////////////////////////////////////////////////////////
    ///////////////// CANCEL PLANS FUNCTIONS //////////////////
    ///////////////////////////////////////////////////////////

    function cancelSavings(uint256 _id) external inSavings(_id) {
        if (savingsCancelled[_id]) {
            revert Atium_Cancelled();
        }
        savingsCancelled[_id] = true;

        (bool sent, ) = payable(msg.sender).call{value: savingsById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 0, savingsById[_id].amount);
    }

    function cancelAllowance(uint256 _id) external inAllowance(_id) {
        if (allowanceCancelled[_id]) {
            revert Atium_Cancelled();
        }
        allowanceCancelled[_id] = true;
        
        (bool sent, ) = payable(msg.sender).call{value: allowanceBalance[_id]}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }

        emit Withdrawn(msg.sender, 1, allowanceById[_id].deposit);
    }

    function cancelTrustfund(uint256 _id) external inTrustfund(_id) {
        if (trustfundCancelled[_id]) {
            revert Atium_Cancelled();
        }
        trustfundCancelled[_id] = true;
        
        (bool sent, ) = payable(msg.sender).call{value: trustfundBalance[_id]}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }    

        emit Withdrawn(msg.sender, 2, trustfundById[_id].amount);
    }

    function cancelGift(uint256 _id) external inGift(_id) {
        if (giftCancelled[_id]) {
            revert Atium_Cancelled();
        }
        giftCancelled[_id] = true;
        
        (bool sent, ) = payable(msg.sender).call{value: giftById[_id].amount}("");
        if (!sent) {
            revert Atium_TransactionFailed();
        }     

        emit Withdrawn(msg.sender, 2, giftById[_id].amount);
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

    ///////////////////////////////////////////////////////
    //////////////// LOYALTY (FOR REWARD) /////////////////
    ///////////////////////////////////////////////////////
    /*
    function checkLoyaltyId(uint256 _id) public view returns (address) {
        return loyaltyId[_id];
    }

    function checkUserLoyaltyPoints(address _user) public view returns (uint256) {
        return loyaltyPoints[_user];
    }
    */

    ///////////////////////////////////////////////////////
    ///////////////// RECEIVER MODIFIERS //////////////////
    ///////////////////////////////////////////////////////

    modifier rAllowance(uint256 _id) {
        if (allowanceById[_id].receiver != msg.sender) {
            revert Atium_NotReceiverId();
        }
        _;
    }

    modifier rTrustfund(uint256 _id) {
        if (trustfundById[_id].receiver != msg.sender) {
            revert Atium_NotReceiverId();
        }
        _;
    }

    modifier rGift(uint256 _id) {
        if (giftById[_id].receiver != msg.sender) {
            revert Atium_NotReceiverId();
        }
        _;
    }


    receive() payable external {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";

error Atium_NotOwnerId();
error Atium_OnlyFutureDate();
error Atium_ZeroInput();

contract AtiumPlan {
    using Counters for Counters.Counter;

    Counters.Counter private _atiumId;
    Counters.Counter private _savingsId;
    Counters.Counter private _allowanceId;
    Counters.Counter private _trustfundId;
    Counters.Counter private _giftId;

    mapping(uint256 => AtiumList) internal atiumById;
    mapping(uint256 => SavingsList) internal savingsById;
    mapping(uint256 => AllowanceList) internal allowanceById;
    mapping(uint256 => TrustFundList) internal trustfundById;
    mapping(uint256 => GiftList) internal giftById;

    mapping(uint256 => uint256) internal allowanceDate;
    mapping(uint256 => uint256) internal trustfundDate;

    enum Select {SAVINGS, ALLOWANCE, TRUSTFUND, GIFT}
    //SAVINGS = 0, ALLOWANCE = 1, TRUSTFUND = 2. GIFT = 3

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event Savings(uint256 id, address indexed user, uint256 deposit, uint256 goal, uint256 time);

    event Allowance(
        uint256 id, 
        address indexed user,
        address indexed receiver, 
        uint256 deposit,
        uint256 startDate,
        uint256 withdrawal,
        uint256 interval
        );

    event Trustfund(
        uint256 id, 
        address indexed user,
        address indexed receiver, 
        uint256 deposit,
        uint256 startDate,
        uint256 withdrawal,
        uint256 interval
        );

    event Gift(
        uint256 id, 
        address indexed user, 
        address indexed receiver, 
        uint256 deposit,
        uint256 date
        );

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

        emit Savings(
            _savingsId.current(), 
            msg.sender, 
            savingsById[_savingsId.current()].amount,
            _goal, 
            0
            );
    }

    function savingsPlanTime(uint256 _time) external {
        if (_time == 0) {
            revert Atium_ZeroInput();
        }
        _atiumId.increment();
        _savingsId.increment();
        _time += block.timestamp;

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

        emit Savings(
            _savingsId.current(), 
            msg.sender, 
            savingsById[_savingsId.current()].amount,
            0, 
            _time
            );
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
        _startDate += block.timestamp;

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

        emit Allowance(
        _allowanceId.current(), 
        msg.sender,
        _receiver, 
        allowanceById[_allowanceId.current()].deposit,
        _startDate,
        _amount,
        _interval
        );
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
        _startDate += block.timestamp;

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

        emit Trustfund(
        _trustfundId.current(), 
        msg.sender,
        _receiver, 
        trustfundById[_trustfundId.current()].amount,
        _startDate,
        _amount,
        _interval
        );
    }

    function giftPlan(address _receiver, uint256 _date) external {

        if (_receiver == address(0) || _date == 0) {
            revert Atium_ZeroInput();
        }

        _atiumId.increment();
        _giftId.increment();
        _date += block.timestamp;

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

        emit Gift(
            _giftId.current(), 
            msg.sender, 
            _receiver, 
            giftById[_giftId.current()].amount,
            _date
            );
    }

    /////////////////////////////////////////////////////
    ////////////// EDIT/UPDATE ATIUM PLANS //////////////
    /////////////////////////////////////////////////////

    function editSavingsPlanGoal(uint256 _id, uint256 _goal) public inSavings(_id) {

        SavingsList memory s = SavingsList ({
            id: _id,
            user: msg.sender,
            amount: savingsById[_id].amount,
            goal: _goal,
            time: 0
        });

        savingsById[_id] = s;

        emit Savings(
            _id, 
            msg.sender, 
            savingsById[_id].amount,
            _goal, 
            0
            );
    }

    function editSavingsPlanTime(uint256 _id, uint256 _time) public inSavings(_id) {

        _time += block.timestamp;

        SavingsList memory s = SavingsList ({
            id: _id,
            user: msg.sender,
            amount: savingsById[_id].amount,
            goal: 0,
            time: _time
        });

        savingsById[_id] = s;

        emit Savings(
            _id, 
            msg.sender, 
            savingsById[_id].amount,
            0, 
            _time
            );
    }

    function editAllowancePlan(
        uint256 _id, 
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external inAllowance(_id) {

        _startDate += block.timestamp;

        AllowanceList memory al = AllowanceList ({
            id: _id,
            sender: msg.sender,
            receiver: _receiver,
            deposit: allowanceById[_id].deposit,
            startDate: _startDate += block.timestamp,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        allowanceById[_id] = al;
        allowanceDate[_id] = _startDate;

        emit Allowance(
        _id, 
        msg.sender,
        _receiver, 
        allowanceById[_id].deposit,
        _startDate,
        _amount,
        _interval
        );
    }

    function editTrustfundPlan(
        uint256 _id, 
        address _receiver, 
        uint256 _startDate, 
        uint256 _amount, 
        uint256 _interval
        ) external inTrustfund(_id) {

        _startDate += block.timestamp;

        TrustFundList memory t = TrustFundList ({
            id: _id,
            sender: msg.sender,
            receiver: _receiver,
            amount: trustfundById[_id].amount,
            startDate: _startDate,
            withdrawalAmount: _amount,
            withdrawalInterval: _interval
        });

        trustfundById[_id] = t;
        trustfundDate[_id] = _startDate;

        emit Trustfund(
        _id, 
        msg.sender,
        _receiver, 
        trustfundById[_id].amount,
        _startDate,
        _amount,
        _interval
        );
    }

    function editGiftPlan(uint256 _id, address _receiver, uint256 _date) external inGift(_id) {

        _date += block.timestamp;

        GiftList memory g = GiftList ({
            id: _id,
            sender: msg.sender,
            receiver: _receiver,
            amount: giftById[_id].amount,
            date: _date
        });

        giftById[_id] = g;

        emit Gift(
            _id, 
            msg.sender, 
            _receiver, 
            giftById[_id].amount,
            _date
            );
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