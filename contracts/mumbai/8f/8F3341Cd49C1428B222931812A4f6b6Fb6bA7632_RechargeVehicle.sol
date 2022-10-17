/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

// SPDX-License-Identifier: PUCRS

pragma solidity >= 0.8.12;

contract RechargeVehicle {
    
    struct RechargeEvent{
        string codStation;
        string codConsumer;
        uint datReservation;
        string status;
        uint datEndRecharge;
        string desOffer;
        uint lastUpdate;
    }

    mapping(uint => RechargeEvent) rechargeEvent;

    event UpdateMessages(string oldStr, string newStr);

    string public message;
    uint rechargeEventCount;

    constructor (){
        //setStationReservation(_codStation, _codConsumer);
        //clearReservation();
        rechargeEventCount=0;
    }

    function compareStrings(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function getRechargeEventClosure() private view returns (bool){
        if ( 
            (compareStrings(rechargeEvent[0].status, "Encerrado") == true) && 
            (compareStrings(rechargeEvent[0].status, "Cancelado") == true))  {
                return true;
            } else return false;
    }

    function setStationReservation(string memory _codStation, string memory _codConsumer) public returns (bool) {
        if (rechargeEventCount == 0){
            rechargeEvent[0] = RechargeEvent(
                _codStation,
                _codConsumer,
                block.timestamp,
                "Reservado",
                0,
                "",
                block.timestamp
            );
            return true;
        } else return false;
    }

    function setStatusRecharge(string memory _status) public returns (string memory) {
        string memory returnMessage;
        if (getRechargeEventClosure() == false){
            if (
                (compareStrings(_status, "Encerrado") == true) &&
                (compareStrings(_status, "Encerrado") == true) ) 
                {
                    rechargeEvent[0].datEndRecharge = block.timestamp;
                }
            rechargeEvent[0].status = _status;
            returnMessage = "Status Alterado";
        } else returnMessage = string.concat("Nao foi possivel alterar o contrato com status ", rechargeEvent[0].status);
        return returnMessage;
    }

    function setOffer(string memory _desOffer) public returns (bool){
        if (getRechargeEventClosure() == false){
            rechargeEvent[0].desOffer = _desOffer;
            return true;    
        } else return false;
    }

    function getRechargeInformation() public view returns (RechargeEvent[] memory){
        RechargeEvent[] memory returnValue = new RechargeEvent[](1);
        RechargeEvent storage recharge = rechargeEvent[0];
        returnValue[0]=recharge;
        return returnValue;
    }



    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }

    
    function getMessage() public view returns (string memory) {
        return message;
    }

}