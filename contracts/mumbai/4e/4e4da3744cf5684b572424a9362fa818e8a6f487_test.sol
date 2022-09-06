/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

contract test {

    //Details of the agenda
    struct agendaDetails {
        uint256 agendaId;
    }

    //mapping for getting agenda details
    mapping(uint256 => agendaDetails[]) public getAgendaInfo;

    function addAgenda(uint256 eventTokenId, uint256 agendaId)  external  {
        getAgendaInfo[eventTokenId].push(agendaDetails(agendaId
        ));
    }

    function deleteAgenda(uint256 eventTokenId, uint256 agendaId)  external  {
        getAgendaInfo[eventTokenId].push(agendaDetails(agendaId
        ));
    }

    function deleteAgenda1(uint256 eventTokenId, uint256 agendaId)  external  {
         delete getAgendaInfo[eventTokenId][agendaId];
    }
}