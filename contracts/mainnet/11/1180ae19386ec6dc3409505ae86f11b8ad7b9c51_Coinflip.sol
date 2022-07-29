// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./VRFConsumerBase.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Coinflip is Ownable, VRFConsumerBase {

    using SafeMath for uint256;

    uint public contractBalance;
    uint public feeBalance;
    uint public minBetAmount = 2 ether;
    uint public betFee = 5;

    struct Bet {
        address playerAddress;
        uint betValue;
        uint headsTails;
    }

    mapping (bytes32 => Bet) public bets;
    mapping (address => uint) public playerWinnings;

    struct Game {
		address addr;
		uint blocknumber;
		uint blocktimestamp;
        uint bet;
        bool winner;
    }

	Game[] lastPlayedGames;
    Game newGame;

    event BetPlaced(bytes32 indexed id, address indexed player, uint256 amount, uint headsTails);
    event BetResult(bytes32 indexed id, address indexed player, uint256 amount, bool won);
    event userWithdrawal(address indexed caller, uint256 amount);

    bytes32 internal keyHash;
    uint256 internal fee;

    /// @notice set the necessary address, and value for Chainlink's VRF, set initial contract balance.
    /// @dev Params from _coorAddress to _keyHash necessary for Chainlink's VRF.
    constructor( address _coorAddress, address _linkAddress, uint256 _fee, bytes32 _keyHash ) VRFConsumerBase (
            _coorAddress,
            _linkAddress
        )  payable {
        contractBalance = msg.value;
        fee = _fee;
        keyHash = _keyHash;
        feeBalance = 0;
    }
    /// @notice start the bet
    /// @param oneZero - The numerical value of heads(0) or tails(1)
    function placeBet(uint256 oneZero) public payable {

        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(contractBalance > msg.value, "We don't have enough funds");
        uint betAmount = msg.value;
        betAmount = SafeMath.mul(betAmount, 100);
        betAmount = SafeMath.div(betAmount, SafeMath.add(100, betFee));
        require(betAmount >= minBetAmount, "Min Bet Amount is 2 Matic");
        uint feeAmount = SafeMath.sub(msg.value, betAmount);
        feeBalance = SafeMath.add(feeBalance, feeAmount);

        bytes32 requestId = getRandomNumber();

        bets[requestId] = Bet(msg.sender, betAmount, oneZero);
        emit BetPlaced(requestId, msg.sender, betAmount, oneZero);

    }

    /// @notice Add extra obscurity regarding the random number.
    /// @dev Remove and incorporate a simple uint variable to save gas.
    ///      Call in the placeBet function.
    function getRandomNumber() internal returns(bytes32 requestId) {
        return requestRandomness(keyHash, fee);
    }

    /// @notice Chainlink's VRF returns a call to this function with the requestId and random
    ///         number
    /// @dev Validate who is the winner.
    /// @param _requestId The return value used to track the VRF call with the returned uint
    /// @param _randomness The verifiable random number returned from Chainlink's VRF API
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        uint result = _randomness % 2;
        Bet memory bet = bets[_requestId];
        uint256 payoutAmt = payout(bet, result);
        emit BetResult(_requestId, bet.playerAddress, payoutAmt, bet.headsTails == result);

        newGame = Game({
            addr: bet.playerAddress,
            blocknumber: block.number,
            blocktimestamp: block.timestamp,
            bet: payoutAmt,
            winner: bet.headsTails == result
        });

        lastPlayedGames.push(newGame);
    }

    function payout(Bet memory bet, uint flipResult) private returns (uint256) {
        if (bet.headsTails != flipResult) {
            contractBalance = SafeMath.add(contractBalance, bet.betValue);
        } else {
            contractBalance = SafeMath.sub(contractBalance, bet.betValue);
            playerWinnings[bet.playerAddress] = SafeMath.add(playerWinnings[bet.playerAddress], SafeMath.mul(bet.betValue, 2));
        }

        return bet.betValue;
    }

    function withdrawUserWinnings() public {
        require(playerWinnings[msg.sender] > 0, "No funds to withdraw");
        uint toTransfer = playerWinnings[msg.sender];
        playerWinnings[msg.sender] = 0;
        payable(msg.sender).transfer(toTransfer);
        emit userWithdrawal(msg.sender, toTransfer);
    }

    function getWinningsBalance() public view returns(uint){
        return playerWinnings[msg.sender];
    }

    function getGameCount() public view returns(uint) {
        return lastPlayedGames.length;
	}

	function getGameEntry(uint index) public view returns(address addr, uint blocknumber, uint blocktimestamp, uint bet, bool winner) {
		return (
            lastPlayedGames[index].addr,
            lastPlayedGames[index].blocknumber,
            lastPlayedGames[index].blocktimestamp,
            lastPlayedGames[index].bet,
            lastPlayedGames[index].winner
        );
	}

    /**
    *@notice The following functions are reserved for the owner of the contract.
     */

    function fundContract() public payable onlyOwner {
        contractBalance = contractBalance.add(msg.value);
    }

    function fundWinnings() public payable onlyOwner {
        playerWinnings[msg.sender] = playerWinnings[msg.sender].add(msg.value);
    }

    function withdrawAll() public onlyOwner {
        uint toTransfer = contractBalance;
        contractBalance = 0;
        payable(msg.sender).transfer(toTransfer);
    }

    function withdrawFees() public onlyOwner {
        uint toTransfer = feeBalance;
        feeBalance = 0;
        payable(msg.sender).transfer(toTransfer);
    }

    function getLinkAmount()  public view returns(uint){
        return LINK.balanceOf(address(this));
    }

}