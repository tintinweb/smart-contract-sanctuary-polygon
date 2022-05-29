// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Signal{

    address public owner;
    uint256 private counter;

    constructor(){
        owner = msg.sender;
        counter = 0;
    }

    struct signal {
        address signaler;
        uint256 id;
        string signalTxt;
        string signalImg;
    }

    event signalCreated (
        address signaler,
        uint256 id,
        string signalTxt,
        string signalImg
    );

    mapping (uint256 => signal) Signals;

    function addSignal(string memory signalTxt, string memory signalImg)
    public 
    payable {
        require(msg.value == (1 ether), "Please submit 1 tMATIC");
        signal storage newSignal = Signals[counter]; 
        newSignal.signaler = msg.sender;
        newSignal.id = counter;
        newSignal.signalTxt = signalTxt;
        newSignal.signalImg = signalImg;

        emit signalCreated(
            msg.sender,
            counter,
            signalTxt,
            signalImg
            ); 
        counter++;
        
       payable(owner).transfer(msg.value);
    }


    function getSignal(uint256 id) public view returns(
        string memory,
        string memory,
        address
    ){
        require(id < counter, "No such Signal");
        signal storage s = Signals[id];
        return(s.signalTxt, s.signalImg, s.signaler);
    }

}