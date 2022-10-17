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

    constructor (){
        //clearReservation();
    }

    function compareStrings(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function setStationReservation(string memory _codStation, string memory _codConsumer) private {
        rechargeEvent[0] = RechargeEvent(
            _codStation,
            _codConsumer,
            block.timestamp,
            "Reservado",
            0,
            "",
            block.timestamp
        );
    }

    function setStatusRecharge(string memory _status) public returns (string memory) {
        string storage recharge_status=rechargeEvent[0].status;
        if ( 
            (compareStrings(recharge_status, "Encerrado") == false) && 
            (compareStrings(recharge_status, "Cancelado") == false))  {
                rechargeEvent[0].status = _status;
                if (compareStrings(_status, "Encerrado") == true) {
                    rechargeEvent[0].datEndRecharge = block.timestamp;
                }
                return "Status Alterado";
            } else return string.concat("Nao foi possivel alterar o contrato com status ", recharge_status);
    }

    function setOffer() public returns (bool){
        rechargeEvent[0].desOffer = "Adiiciona Oferta";
        return true;    
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