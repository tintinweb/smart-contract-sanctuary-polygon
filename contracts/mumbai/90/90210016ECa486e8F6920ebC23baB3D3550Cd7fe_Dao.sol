// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



//interfacce

interface IdaoContract {
    function balanceOf(address, uint256) external view returns(uint256);
}

contract Dao {

    //address del proprietario
    address public owner;

    //id prossima proposta
    uint256 nextProposal;

    //quali token possono votare?
    uint256[] public validTokens;

    //riferimento all'interfaccia
    IdaoContract daoContract;

    constructor () {
        owner = msg.sender;
        nextProposal = 1;
        //indirizzo contratto che ha emesso i token che possono votare (esempio gli nft-foto di stefano)
        daoContract = IdaoContract (0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        //id dei token del contratto sopra abilitati al voto(quali nft sono abilitati al voto)
        validTokens = [55785353262448398486964818137556029021018938249835471253065811767086723104769];
    }

    //struttura dati di ogni proposta
    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 voteUp;
        uint256 voteDown;
        address[] canVote;
        uint256 maxVote;
        mapping (address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    //mappa la coppia idProposta => strutturaProposta
    mapping(uint256 => proposal) public Proposals;

    //creo un evento per ogni volta che una proposta è creata
    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer,
        uint256 time
    );

    //creo evento per ogni nuovo voto
    event newVote(
        uint256 voteUp,
        uint256 voteDown,
        address voter,
        uint256 proposal,
        bool votedfor
    );

    //una volta che l'owner ha contato i voti, tramite l'evento ci dice quale id è/non è passato
    event proposalCount(
        uint256 id,
        bool passed
    );

    function setNewDaoOwner(address _newOwnerAddress) public {
        require (msg.sender == owner, "Only Owner can set a new Owner");
        owner = _newOwnerAddress;

    }

    //controlla che se qualcuno cerca di creare una proposta,deve essere in possesso di uno degli nft accettati dalla dao
    function checkProposalEligibility(address _proposalist) private view returns(bool) {
        for(uint i = 0; i < validTokens.length; i++) {
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    //controlla che chi vota sia inserito nella lista della struttura della proposta che si vuole votare
    function checkVoteEligibility(uint256 _id, address _voter) private view returns(bool) {
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    //creo una nuova proposta
    function createProposal(string memory _description, address[] memory _canVote, uint256 _time ) public {

        //controllo che il porponente possa farlo
        require (checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");

        //creo una nuova proposta nell' array Proposals
        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + _time;
        newProposal.canVote = _canVote;
        newProposal.maxVote = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender, _time);

        nextProposal ++;
    }

    //vota la porposta _id > true se si, false se no. 
    function voteOnProposal(uint256 _id, bool _vote) public {

        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already vote on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        //creo un istanza locale dell oggetto proposal(array) che viene mappato da Proposals(mapping) con l'id che passo all'inizio.
        proposal storage p = Proposals[_id];

        if (_vote) {
            p.voteUp ++;
        } else {
            p.voteDown ++;
        }

        //registro che il msg.sender ha votato alla proposta p appena istanziata, aggiornando il suo stato di voto
        p.voteStatus[msg.sender] = true;

        emit newVote(p.voteUp, p.voteDown, msg.sender, _id, _vote);
    }

    //funzione che conta i voti emessi per la proposta _id. solo l'owner della dao puo chiamarla
    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner can count votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count alredy conducted");

        //come nel voto: creo un istanza della proposta(_id) salvata con id(_id) nel nostro mapping delle proposte.
        //an istance from our mapping of Proposals of the proposals 
        proposal storage p = Proposals[_id];

        if (Proposals[_id].voteDown < Proposals[_id].voteUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner can add tokens");

        validTokens.push(_tokenId);
    }

}