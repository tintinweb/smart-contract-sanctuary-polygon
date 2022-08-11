/**
 *Submitted for verification at polygonscan.com on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract spreadBet{
    
    struct Bet{
        uint value;
        uint8 option;
    }

    // Important addresses
    address payable private owner;
    address payable private admin;
    
    // Public vars
    address payable[] public bettors;        // holds all adresses
    mapping (address => Bet) public bets;    // maps adress to value and choice
    uint[] public bets_sum;
    uint32 public bet_id;
    uint public bet_time;
    uint public closing_time;
    int8 public result;
    uint8 public options_num;
    bool public canceled;
    string public description;
    uint32 public dex_fee;
    uint public min_bet;
    

IERC20 public usdt;

function setusdt(address _usdt)public{
 usdt= IERC20(_usdt);
}

    // Consts
    uint32 constant hour = 60*60;

    // Match constructor - this contract contains all bets which belongs to certain match
    constructor(uint32 _bet_id, address payable _admin, uint _bet_time, uint _closing_time,
                uint8 _options_num, string memory _description, uint32 _dex_fee, uint _min_bet) public {
        owner = msg.sender;         // owning contract
        admin = _admin;             // set admin to prevent owning contract failure
        bet_id = _bet_id;
        bet_time = _bet_time;   // match start time
        closing_time = _closing_time;
        canceled = false;
        result = -1;                // -1 unkblock.timestamp ... the rest corresponds to option
        options_num = _options_num; // possible match results
        bets_sum = new uint[](options_num);
        description = _description;
        dex_fee = _dex_fee;
        min_bet = _min_bet;
    }
    
    // ------------ USER FUNCTIONS -------------


// contract balance 
// function name change - place , create bet 
// constructor value 
// 

    function createBet(uint8 option) external payable {
        //require(block.timestamp < closing_time && !canceled, "bet cannot be made block.timestamp");
        // require(option >= 0 && option < options_num, "impossible option");
        // require(msg.value >= min_bet, "too low bet");
              uint funds = msg.value*dex_fee/1000;          // dev fee


        if (bets[msg.sender].value == 0){
            bets[msg.sender].value = funds;
            bets[msg.sender].option = option;
            bets_sum[option] += funds;
            bettors.push(msg.sender);
        } else {
            bets_sum[bets[msg.sender].option] -= bets[msg.sender].value;
            bets[msg.sender].value += funds;
            bets[msg.sender].option = option;
            bets_sum[option] += bets[msg.sender].value;
        }
    }

    function placeBet(uint8 option) external payable {
        //require(block.timestamp < closing_time && !canceled, "bet cannot be made block.timestamp");
        // require(option >= 0 && option < options_num, "impossible option");
        // require(msg.value >= min_bet, "too low bet");
              uint funds = msg.value*dex_fee/1000;          // dev fee


        if (bets[msg.sender].value == 0){
            bets[msg.sender].value = funds;
            bets[msg.sender].option = option;
            bets_sum[option] += funds;
            bettors.push(msg.sender);
        } else {
            bets_sum[bets[msg.sender].option] -= bets[msg.sender].value;
            bets[msg.sender].value += funds;
            bets[msg.sender].option = option;
            bets_sum[option] += bets[msg.sender].value;
        }
    }

    function withdraw_funds() external {
        // you can withraw funds from match which did not start yet or has been canceled
        require(block.timestamp < closing_time || canceled, "funds cannot be withdrawn");
        
        uint return_value;
        if (canceled){
            return_value = bets[msg.sender].value*1000/dex_fee;  // return dev fee
        } else {
            return_value = bets[msg.sender].value;
        }
        bets_sum[bets[msg.sender].option] -= bets[msg.sender].value;
        bets[msg.sender].value = 0;
        msg.sender.transfer(return_value);
    }
    
    function claim_win() external {
        require(result >= 0 && !canceled, "match is not finished");
        require(uint8(result) == bets[msg.sender].option, "you are not a winner");
        require(bets[msg.sender].value > 0, "your funds has been already withdrawn");
        
        uint winned_sum = 0;
        uint winner_bet = bets[msg.sender].value; 
        for (uint8 i = 0; i < options_num; i++){
            if (i != uint8(result)) {
                uint option_win = bets_sum[i]*winner_bet/bets_sum[uint(result)];
                winned_sum += option_win;
                bets_sum[i] -= option_win;
            }
        }
        winned_sum += bets[msg.sender].value;
        bets_sum[uint(result)] -= winner_bet;
        bets[msg.sender].value = 0;
        msg.sender.transfer(winned_sum*(dex_fee+10)/dex_fee);   // return 1% of fee
    }
    
    // ------------ ADMIN FUNCTIONS ------------
    
    // GETTERS
    
    function get_options_value() public view returns(uint[] memory) {
        return bets_sum;
    }
    
    function bets_sums() public view returns(uint) {
        uint sum;
        for (uint8 i = 0; i < options_num; i++) {
            sum += bets_sum[i];
        }
        return sum;
    }
    
    function get_address_option(address addr) external view returns(int16) {
        if (bets[addr].value > 0) {
            return bets[addr].option;
        } else {
            return -1;
        }
    }
    
    function get_unpaid_winners_in_nth_100(uint32 n) public view returns(address payable[] memory) {
        require(result >= 0, "no result - no unpaid winner");
        
        address payable[] memory ret = new address payable[](100);
        uint max_size = (n+1)*100;
        if (bettors.length < max_size){
            max_size = bettors.length;
        }
        for (uint32 i = n*100; i < max_size; i++){
            if (bets[bettors[i]].value > 0 && bets[bettors[i]].option == uint8(result)){
                ret[i] = bettors[i];
            }
        }
        return ret;
    }
    
    function get_bettors_num() public view returns(uint32) {
        return uint32(bettors.length);
    }
    
    // SETTERS
    
    function set_result(uint8 _result) external {
        require(msg.sender == owner || msg.sender == admin, "only owner can call this");
        require(_result >= 0 && _result < options_num, "impossible result");
        require(bet_time < block.timestamp, "match is not finished yet");
        require(!canceled, "match was canceled");
        require(bets_sum[_result] > 0 && bets_sum[_result] < bets_sums());
        
        result = int8(_result);
    }
    
    function cancel_bet() external {
        require(msg.sender == owner || msg.sender == admin, "only owner can call this");
        require(canceled == false, "the match is already canceled");
        require(result < 0, "match has already result");
        
        canceled = true;
    }
    
    // CROWD CONTROL

    function return_funds(address payable recipient) external {
        // in case of canceling the match, this method return funds of certain address
        require(canceled, "match is not canceled, funds cannot be returned");
        
        uint return_value = bets[recipient].value*1000/dex_fee;   // return dex_fee
        bets_sum[bets[recipient].option] -= bets[recipient].value;
        bets[recipient].value = 0;
        recipient.transfer(return_value);
    }
    
    function payout(address payable winner) external {
        require(result >= 0 && !canceled, "match is not finished");
        require(uint8(result) == bets[winner].option, "you are not a winner");
        require(bets[winner].value > 0, "your funds has been already withdrawn");
        require(block.timestamp > bet_time + 24*3*hour, "too soon to autopayout");
        
        uint winned_sum = 0;
        uint winner_bet = bets[msg.sender].value; 
        for (uint8 i = 0; i < options_num; i++){
            if (i != uint8(result)) {
                uint option_win = bets_sum[i]*winner_bet/bets_sum[uint(result)];
                winned_sum += option_win;
                bets_sum[i] -= option_win;
            }
        }
        winned_sum += bets[winner].value;
        bets_sum[uint8(result)] -= bets[winner].value;
        bets[winner].value = 0;
        winner.transfer(winned_sum);        // this payout is triggered by admin, so there is no fee return
    }

    function close_contract() external {
        require(msg.sender == owner || msg.sender == admin, "only owner can call this");    
        require(block.timestamp > bet_time + hour*24*3 || bets_sum[uint8(result)] == 0, "match cannot be closed yet");
        require(result >= 0 || canceled, "match was not resolved");
        
        selfdestruct(admin);
    }
}

// contract EthBet {
//     address payable private admin;
//     mapping (uint32 => Match) public matches;
//     uint32 public dex_fee;
//     uint public min_bet;
    
//     // Parent contract constructor
//     constructor() public {
//         admin = msg.sender;
//         // dex_fee = 975;
//         min_bet = 10 finney; }
    
//     // method for initialisation of match, bet_time is in UTC unix time in sec
//     function init_match(uint bet_time, uint closing_time, uint8 options_num, string calldata description, uint32 _id) external {
//         require(msg.sender == admin, "only owner can call this");
//         require(options_num > 1, "every match must have at least two stacks");
//         require(closing_time <= bet_time - 3600, "wrong match times");
//         require(matches[_id] == Match(0), "match with this id already exists");
        
//         matches[_id] = new Match(_id, admin, bet_time, closing_time, 
//                                  options_num, description, dex_fee, min_bet);
//     }

//     // SETTERS
//     function set_dex_fee(uint32 _dex_fee) external {
//         require(msg.sender == admin, "only owner can call this");
//         require(_dex_fee > 500 && dex_fee < 1000, "should be in mille");

//         dex_fee = _dex_fee;
//     }

//     function set_min_bet(uint _min_bet) external {
//         require(msg.sender == admin, "only owner can call this");
//         require(_min_bet > 1 finney, "this would be very small bet");
        
//         min_bet = _min_bet;
//     }
    
//     // GETTERS
//     function get_my_options(uint32[] calldata _id) external view returns(int16[] memory) {
//         uint size = _id.length;
//         int16[] memory ret = new int16[](size);
//         for (uint32 i = 0; i < size; i++) {
//             if (matches[_id[i]].bet_time() != 0) {     
//                 ret[i] = matches[_id[i]].get_address_option(msg.sender);
//             } else {
//                 ret[i] = -2;     // return -2 because match with this is is already destructed
//             }
//         }
//         return ret;
//     }
    
//     // DESTROY CONTRACTS
//     function close_match(uint32 _id) external{
//         require(msg.sender == admin, "only owner can call this");
        
//         matches[_id].close_contract();
//         delete matches[_id];
//     }
    
//     function close_contract() external {
//         require(msg.sender == admin, "only owner can call this");
        
//         selfdestruct(admin);
//     }
// }