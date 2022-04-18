//SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

error BaseError(string codeError, string message);

function throwReachedVoteLimit() pure {
    revert BaseError("REACHED_VOTE_LIMIT", "Voting limit has been reached");
}

function throwCandidateDoesNotExist() pure {
    revert BaseError("CANDIDATE_DOES_NOT_EXIST", "The selected candidate does not exist");
}

function throwInvalidVoterIdentifier() pure {
    revert BaseError("INVALID_VOTER_IDENTIFIER", "Your voter ID is not valid");
}

function throwVoteRegistrationExists() pure {
    revert BaseError("VOTE_REGISTRATION_EXISTS", "There is already a vote counted for this voter ID");
}

function throwVoteRegistrationNotExists() pure {
    revert BaseError("VOTE_REGISTRATION_NOT_EXISTS", "There is not vote registration for this voter ID");
}

function throwNoSupportForTheRegion() pure {
    revert BaseError("NO_SUPPORT_FOR_THE_REGION", "We don't support your region yet");
}

function throwElectorIdWithIncorrectLength() pure {
    revert BaseError("ELECTOR_ID_WITH_INCORRECT_LENGTH", "Elector id with incorrect length. Elector id has 12 digits");
}

/*
 * Principais nomes na candidatura a presidência da República Federativa do Brasil.
 * A numeração segue como disposto no TSE. Disponível em: <https://www.tse.jus.br/partidos/partidos-registrados-no-tse>. Consultado em: 16/abril/2022
 * Ciro Gomes -> PDT -> 12
 * Luiz Lula -> PT -> 13
 * Simone Tebet -> MDB -> 15
 * Jair Bolsonaro -> PL -> 22     
 * Felipe D'Ávila -> NOVO -> 30
 * João Dória -> PSDB -> 45    
 * André Janones -> AVANTE -> 70     
 * 
 */
uint8 constant GOMES = 12;
uint8 constant LULA = 13;
uint8 constant TEBET = 15;
uint8 constant BOLSONARO = 22;
uint8 constant DAVILA = 30;
uint8 constant DORIA = 45;
uint8 constant JANONES = 70;
uint8 constant NULO_BRANCO = 1;

struct Vote {
    uint8 numberOfCandidate;
    //O valor inicial é false
    bool alreadyVoted;
}

contract VoteBr is ERC2771Context {

    address immutable creatorOfContract;
    //Segundo TSE são 147.918.483 milhões de eleitores no Brasil. Disponível em: <https://www.tse.jus.br/imprensa/noticias-tse/2020/Agosto/brasil-tem-147-9-milhoes-de-eleitores-aptos-a-votar-nas-eleicoes-2020>. Consultado em: 16/abril/2022.
    uint32 constant LIMIT_OF_VOTES = 147918483;
    uint32 public totalOfVotes = 0;    
    
    mapping (bytes32 => Vote) private voteOfElector;    
    
    mapping(uint8 => uint32) private candidatesMapping;
    
    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) { 
        creatorOfContract = _msgSender();
        
        candidatesMapping[GOMES] = 0;
        candidatesMapping[LULA] = 0;
        candidatesMapping[TEBET] = 0;
        candidatesMapping[BOLSONARO] = 0;
        candidatesMapping[DAVILA] = 0;
        candidatesMapping[DORIA] = 0;
        candidatesMapping[JANONES] = 0;
        candidatesMapping[NULO_BRANCO] = 0;
    }

    function vote(uint8 numberOfCandidate, uint8[] memory electorId) external {
        checkLimitOfVotes();
        
        checkIfCandidateExists(numberOfCandidate);          

        checkIfElectorIdIsValid(electorId);
        
        bytes32 electorIdHash = keccak256(abi.encode(electorId));
                
        if (checkIfVoteRegistrationExists(electorIdHash)) {
            throwVoteRegistrationExists();
        }
        
        voteOfElector[electorIdHash].alreadyVoted = true;
        voteOfElector[electorIdHash].numberOfCandidate = numberOfCandidate;        

        candidatesMapping[numberOfCandidate] += 1;

        totalOfVotes++;
    }

    function checkLimitOfVotes() private view {
        if (totalOfVotes > LIMIT_OF_VOTES) {
            throwReachedVoteLimit();
        }        
    }

    function checkIfCandidateExists(uint8 number) private pure {
                
        if (number == GOMES) {            
            return;        
        } 
        
        if (number == LULA) {
            return;        
        } 
        
        if (number == TEBET) {
            return;        
        } 
        
        if (number == BOLSONARO) {
            return;        
        } 
        
        if (number == DAVILA) {
            return;        
        } 
        
        if (number == DORIA) {
            return;         
        } 
        
        if (number == JANONES) {
            return;
        } 
        
        if (number == NULO_BRANCO) {
            return;
        }                
        
        throwCandidateDoesNotExist();
        
    }
    
    function checkIfElectorIdIsValid(uint8[] memory electorId) private pure {
        if (electorId.length < 12 || electorId.length > 13) {
            throwElectorIdWithIncorrectLength();
        }        
        
        uint8[2] memory RO = [2, 3];        
        
        if (!(electorId[8] == RO[0] && electorId[9]  == RO[1])) {
            throwNoSupportForTheRegion();
        }
        
        uint16 sum = 0;
        uint8 j = 2;        
        for (uint8 i = 0; i <= 7; i++) {
            sum += electorId[i] * j;
            j++;
        }

        uint16 primaryVerifyDigite = sum % 11;
        
        if (primaryVerifyDigite == 10) {
            primaryVerifyDigite = 0;
        }

        sum = 0;     
        uint8 k = 7;   
        for (uint8 i = 8; i <= 9; i++) {
            sum += electorId[i] * k;
            k++;
        }

        sum += primaryVerifyDigite * 9;

        uint16 secundVerifyDigite = sum % 11;
        if (secundVerifyDigite == 10) {
            secundVerifyDigite = 0;
        }

        if (!(electorId[10] == primaryVerifyDigite && electorId[11] == secundVerifyDigite)) {
            throwInvalidVoterIdentifier();
        }

    }

    function checkIfVoteRegistrationExists(bytes32 electorIdHash) private view returns (bool) {
        return voteOfElector[electorIdHash].alreadyVoted == true;
    }
   
    function queryMyVote(uint8[] memory electorId) external view returns (uint8) {
        checkIfElectorIdIsValid(electorId);
        
        bytes32 electorIdHash = keccak256(abi.encode(electorId));
                
        if (checkIfVoteRegistrationExists(electorIdHash) == false) {
            throwVoteRegistrationNotExists();
        }

        return voteOfElector[electorIdHash].numberOfCandidate;
    }
       
    function getTotalVotesForCiro() external view returns (uint32) {                
        return  candidatesMapping[GOMES];
    }

    function getTotalVotesForLula() external view returns (uint32) {
        return candidatesMapping[LULA];            
    }

    function getTotalVotesForTebet() external view returns (uint32) {
        return candidatesMapping[TEBET];
    }

    function getTotalVotesForBolsonaro() external view returns (uint32) {
        return candidatesMapping[BOLSONARO];
    }

    function getTotalVotesForDavila() external view returns (uint32) {
        return candidatesMapping[DAVILA];
    }

    function getTotalVotesForDoria() external view returns (uint32) {
        return candidatesMapping[DORIA];
    }

    function getTotalVotesForJanones() external view returns (uint32) {
        return candidatesMapping[JANONES];
    }

    function getTotalVotesNulosBrancos() external view returns (uint32) {
        return candidatesMapping[NULO_BRANCO];       
    }

    function killContract() external onlyOwner {        
        selfdestruct(payable(creatorOfContract));        
    }

    modifier onlyOwner() {
        require(_msgSender() == creatorOfContract, "NOT_AUTHORIZED"); 
        _;       
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}