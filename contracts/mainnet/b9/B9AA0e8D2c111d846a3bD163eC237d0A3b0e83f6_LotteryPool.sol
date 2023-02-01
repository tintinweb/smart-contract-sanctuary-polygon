// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


abstract contract LDataStorage {

    uint256 lcIndex;
    uint256 lwIndex;

    mapping(uint256 => address[]) _lotteryCandidates;
    mapping(uint256 => address[]) _lotteryWinners;

    function _resetLotteryCandidates() internal {
        lcIndex++;
    }
    function _resetLotteryWinners() internal {
        lwIndex++;
    }

    function todayLotteryCandidates() public view returns(address[] memory addr) {
        uint256 len = _lotteryCandidates[lcIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _lotteryCandidates[lcIndex][i];
        }
    }

    function lastLotteryWinners() public view returns(address[] memory addr) {
        uint256 len = _lotteryWinners[lwIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _lotteryWinners[lwIndex][i];
        }
    }

    function lotteryCandidatesCount() public view returns(uint256) {
        return _lotteryCandidates[lcIndex].length;
    }

    function lastLotteryWinnersCount() public view returns(uint256) {
        return _lotteryWinners[lwIndex].length;
    }


    mapping(address => uint256) public _userAllEarned_USD;

    uint256 public allPayments_USD;
    uint256 public allPayments_MATIC;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function lotteryWinnersCount() public view returns(uint256) {
        uint256 count = lotteryCandidatesCount();
        return count % 20 == 0 ? count * 5/100 : count * 5/100 + 1;
    }

    function lotteryFractionValue() public view returns(uint256) {
        uint256 denom = lotteryWinnersCount();
        if(denom == 0) {denom = 1;}
        return balance() / denom;
    }


    uint256 utIndex;
    mapping(uint256 => mapping(address => uint256)) _userTickets;

    uint256 public lotteryTickets;

    function userTickets(address userAddr) public view returns(uint256) {
        return _userTickets[utIndex][userAddr];
    }

    function _resetUserTickets() internal {
        utIndex++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LDataStorage.sol";

contract LotteryPool is LDataStorage {
    
    address public rePoint;

    constructor (address _repoint) {
        rePoint = _repoint;
    }

    modifier onlyrePoint() {
        require(msg.sender == rePoint, "only rePoint can call this function");
        _;
    }

    function distribute(uint256 MATIC_USD) public onlyrePoint {
        _resetLotteryWinners();

        address[] storage lotteryCandidates = _lotteryCandidates[lcIndex];
        address[] storage lotteryWinners = _lotteryWinners[lwIndex];

        uint256 _balance = balance();
        uint256 _balanceUSD = _balance * MATIC_USD/10**18;

        uint256 winnersCount = lotteryWinnersCount();
        uint256 candidatesCount = lotteryCandidatesCount();
        uint256 lotteryFraction = lotteryFractionValue();
        address winner;

        uint256 randIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp, block.difficulty, MATIC_USD
        )));
        for(uint256 i; i < winnersCount; i++) {
            randIndex = uint256(keccak256(abi.encodePacked(randIndex, i))) % candidatesCount;
            candidatesCount--;
            winner = lotteryCandidates[randIndex];
            lotteryCandidates[randIndex] = lotteryCandidates[candidatesCount];
            lotteryWinners.push(winner);
            _userAllEarned_USD[winner] += lotteryFraction * MATIC_USD/10**18;
            payable(winner).transfer(lotteryFraction);
        }
        if(balance() == 0) {
            allPayments_USD += _balanceUSD;
            allPayments_MATIC += _balance;
        }
        delete lotteryTickets;
        _resetLotteryCandidates();
        _resetUserTickets();
    }

    function addAddr(address userAddr, uint256 numTickets) public payable onlyrePoint {
        for(uint256 i; i < numTickets; i++) {
            _lotteryCandidates[lcIndex].push(userAddr);
        }
        lotteryTickets += numTickets;
        _userTickets[utIndex][userAddr] += numTickets;
    }

    receive() external payable{}

    function panicWithdraw() public onlyrePoint {
        payable(rePoint).transfer(address(this).balance);
    }
}