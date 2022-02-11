/**
 *Submitted for verification at polygonscan.com on 2022-02-10
*/

pragma solidity 0.8.7;


contract Vote {

    string[] Candidats = ["Fejza", "Blanchon", "Vincent", "Rosset", "Coat", "Hamon", "Lejeune", "Laget-Kamel", "Voisin", "Brouart"];

    mapping(string => uint) nbVoix;
    mapping(address => bool) aVote; 

    uint nbVotes = 0;


    function isCandidat(string memory nom) private view returns(bool) {
        uint i = 0;
        while(i < Candidats.length && keccak256(bytes(nom)) != keccak256(bytes(Candidats[i]))){
            i++;
        }
        return !(i == Candidats.length); 
    }

    function vote(string memory nom) public {
        require(aVote[msg.sender] == false, "Vous avez deja vote !!");
        require(isCandidat(nom), "Cette personne ne s est pas presente !");

        nbVoix[nom] += 1;
        aVote[msg.sender] = true;
        nbVotes++;
    }

    function getNbVoix(string memory nom) public view returns (uint) {
        require(isCandidat(nom), "Cette personne ne s est pas presente !");
        return nbVoix[nom];
    }

    function getNbVotes() public view returns (uint) {
        return nbVotes;
    }

    function getWinner() public view returns (string memory) {
        uint max = nbVoix[Candidats[0]];
        string memory winner = Candidats[0];

        uint i = 1;
        while(i < Candidats.length) {
            if(nbVoix[Candidats[i]] > max) {
                max = nbVoix[Candidats[i]];
                winner = Candidats[i];
            }
            i++;
        }

        return winner;
    }

}