/**
 *Submitted for verification at polygonscan.com on 2022-08-15
*/

pragma solidity >=0.4.22 <0.6.0;

contract XDCJackpot {

    uint256 currentTimeWin;
    address[] addressArr;
    bool activeGame;

    function buttonClick() public payable {
        require(msg.value == 1 ether, "1 XDC required to bet!");
        if (activeGame)
            require(msg.sender != getLast(), "You are already winning!");
        currentTimeWin = now + 5 minutes;
        addressArr.push(msg.sender);
        activeGame = true;
    }

    function claimPrize() public  {
        require(howLong() <= 0, "There is still time left before the Jackpot winner is selected");
        require(msg.sender == getLast(), "You aren't currently winning the Jackpot");
        uint256 bal = address(this).balance;
        msg.sender.transfer(bal);
        activeGame = false;
        delete addressArr;

    }

    function winningTime() public view returns (uint256){
        return currentTimeWin;
    }


    function getLast() public view returns (address){
        require(activeGame, "Game hasn't begun!");
        return addressArr[addressArr.length -1];
    }

    function addresses() public view returns (address[]){
        return addressArr;
    }

    function howLong() public view returns (int256){
        require(activeGame, "Game hasn't begun!");
        return int256(currentTimeWin - now);
    }

    function currentJackpot() public view returns (uint256){
        return(address(this).balance);
    }
}