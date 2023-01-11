// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPolygonSb {
    function registered(address userAddr) external view returns(bool);
    function userTodayPoints(address userAddr) external view returns(uint256);
    function USD_MATIC() external view returns(uint256);
}

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


// ---------------------------------------------------------------------------------------

    mapping(address => uint256) public userAllEarned;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function todayLotteryWinnersCount() public view returns(uint256) {
        return lotteryCandidatesCount() * 5/100 + 1;
    }

    function lotteryFractionValue() public view returns(uint256) {
        return balance() / todayLotteryWinnersCount();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LDataStorage.sol";
import "../IPolygonSb.sol";

contract LotteryPool is LDataStorage {
    
    address polygonSb;
    IPolygonSb PSB;

    constructor (address _polygonSb) {
        polygonSb = _polygonSb;
        PSB = IPolygonSb(_polygonSb);
    }

    modifier onlyPolygonSb() {
        require(msg.sender == polygonSb, "only polygonSb can call this function");
        _;
    }

// shadidan test lazem
    function distribute() public onlyPolygonSb {
        _resetLotteryWinners();

        address[] storage lotteryCandidates = _lotteryCandidates[lcIndex];
        address[] storage lotteryWinners = _lotteryWinners[lwIndex];

        uint256 winnersCount = todayLotteryWinnersCount();
        uint256 candidatesCount = lotteryCandidatesCount();
        uint256 lotteryFraction = lotteryFractionValue();
        address winner;

        uint256 randIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp, block.difficulty, PSB.USD_MATIC()
        )));
        for(uint256 i; i < winnersCount; i++) {
            randIndex = uint256(keccak256(abi.encodePacked(randIndex, i))) % candidatesCount;
            candidatesCount--;
            winner = lotteryCandidates[randIndex];
            lotteryCandidates[randIndex] = lotteryCandidates[candidatesCount];
            lotteryWinners.push(winner);
            userAllEarned[winner] += lotteryFraction;
            payable(winner).transfer(lotteryFraction);
        }
        
        _resetLotteryCandidates();
    }

    function registerInLottery() public payable {
        address userAddr = msg.sender;
        require(
            PSB.registered(userAddr),
            "This address is not registered in Smart Binary Contract!"
        );
        require(
            PSB.userTodayPoints(userAddr) == 0,
            "You Have Points Today"
        );
        uint256 ticketPrice = 1 * PSB.USD_MATIC();
        require(
            msg.value >= ticketPrice,
            "minimum lottery enter price is 1 USD in MATIC"
        );
        uint256 numTickets = msg.value / ticketPrice;
        for(uint256 i; i < numTickets; i++) {
            _lotteryCandidates[lcIndex].push(userAddr);
        }
    }
}