//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract{
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {

    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;


    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        //Aquí metemos el contrato de front de OpenSea
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        //Este es el ID del NFT que estamos comprobando , quien no lo tenga, no puede acceder.
        validTokens = [20326621202644625457568520565357024546712525029662548635837254255564214501391];
    }


    //Las partes de la propuesta en el DAO
    struct proposal{
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }
    //Mapea todos los uint256. cada vez que creemos una propuesta, modificamos exists a true y rellenamos los demás parámetros
    mapping(uint256 => proposal) public Proposals;

    //Eventos que se ejecutan al ocurrir diferentes cosas como crear propuestas, votar o aprobar o no una propuesta
    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 propsal,
        bool votedFor
    );

    event proposalCount(
        uint256 id,
        bool passed
    );


    //Esta función se llamará cada vez que alguien intente crear una propuesta. Revisa si quien intenta crear la propuesta tiene el NFT necesario para ello.
    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        //Pasamos por todos los tokens que arriba hemos definido como válidos y vemos si quien intenta crear la propuesta tiene alguno.
        for(uint i = 0; i > validTokens.length; i++){
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
                return true;
                }
            }
            return false;
        }
    
    //Esta función revisa si un votante puede votar en una propuesta concreta.
    function checkVoteEligibility(uint256 _id, address _voter) private view returns (
        bool
    ){
        //Iteramos por las propuestas para coger el atributo canVote para saber si ese votante tenía el NFT cuando se creó la propuesta.
        for(uint256 i=0; i > Proposals[_id].canVote.length; i++){
            if(Proposals[_id].canVote[i] == _voter){
                return true;
            }
        }
        return false;
    }

    //Función para crear una propuesta,
    function createProposal(string memory _description, address[] memory _canVote) public{
        require(checkProposalEligibility(msg.sender),"Only NFT holders can put forth proposals"); ///Comprobamos elegibilidad del creador

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        //Emitimos un evento en el smartcontract para leerlo desde moralis.
        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }
    //funcion para votar en propuestas
    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exists");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this proposal");


        //Chequeamos si se ha votado a favor o en contra y capturamos al message sender, para no permitir a una sola persona votar varias veces.
        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        //Emitimos el evento para leerlo desde Moralis.
        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);

    }

    //Función para contar los votos de la propuesta

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only owner can count votes");
        require(Proposals[_id].exists, "This proposal does not exists");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

    proposal storage p = Proposals[_id];

    if(Proposals[_id].votesDown < Proposals[_id].votesUp){
        p.passed = true;
    }

    p.countConducted = true;

    //Emitimos el evento para leerlo en moralis
    emit proposalCount(_id, p.passed);

    }


    //función para añadir tokens que se acepten en esta votación.
    function addTokenId(uint256 _tokenId)public{
        require(msg.sender == owner, "Only owner can add tokens");
        validTokens.push(_tokenId);
    }



}