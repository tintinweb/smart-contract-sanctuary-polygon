/**
 *Submitted for verification at polygonscan.com on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IP2PBet {

    function createBet(
        address _betInitiator,
        uint _liquidityByBetInitiator,
        uint _winningAmount,
        uint _matchId,
        uint _tokenId
    )
    external
    payable;

    function joinBet(
        address _betTaker,
        uint _liquidityByBetTaker
    )
    external
    payable;

}

contract P2PBet is IP2PBet {

    address public betInitiator;
    address public betTaker;
    uint public liquidityByBetInitiator;
    uint public liquidityByBetTaker;
    uint public opponentAmount;
    uint public matchId;
    bool public isMatched;
    uint public tokenId;

    receive() external payable {}
 
    function createBet(
        address _betInitiator,
        uint _liquidityByBetInitiator,
        uint _opponentAmount,
        uint _matchId,
        uint _tokenId
    )
    public
    payable
    {
        betInitiator = _betInitiator;
        betTaker = address(0);
        liquidityByBetInitiator = _liquidityByBetInitiator;
        liquidityByBetTaker = 0;
        opponentAmount = _opponentAmount;
        matchId = _matchId;
        isMatched = false;
        tokenId = _tokenId;
    } 

    function joinBet(
        address _betTaker,
        uint _liquidityByBetTaker
    )
    public
    payable
    {
        betTaker = _betTaker;
        liquidityByBetTaker = _liquidityByBetTaker;
        isMatched = true;
    }

}

contract MainContract {

    P2PBet internal p;

    fallback() external payable {}
    receive() external payable {}

    P2PBet[] public bets;

    event BetDeployed(P2PBet _id);

    function createBet(
        uint _opponentAmount,
        uint _matchId,
        uint _tokenId
    ) 
    public
    payable
    returns(P2PBet)
    {
        p = new P2PBet();
        IP2PBet(p).createBet(msg.sender,msg.value,_opponentAmount,_matchId,_tokenId);
        address  _p = address(p);
        payable(_p).transfer(msg.value);
        bets.push(p);
        emit BetDeployed(p);
        return p;
    }

    function joinBet(
        P2PBet _betContractId
    )
    public
    payable
    returns(bool)
    {
        IP2PBet(_betContractId).joinBet(msg.sender,msg.value);
        address _p = address(_betContractId);
        payable(_p).transfer(msg.value);
        return true;
    }

}