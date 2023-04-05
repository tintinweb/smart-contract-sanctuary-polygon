// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IATCNFT.sol";
import "./Proposals.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAO is Proposals, Ownable{

    //Instancia del smart contract ATCNFT.
    IATCNFT public ATCNFT;
    IERC20 public ATCC;

    constructor(address _addressATCNFT, address _addressATCC){
        ATCNFT = IATCNFT(_addressATCNFT);
        ATCC = IERC20(_addressATCC);
    }

    //Contador para establecer el id de cada propuesta.
    uint256 public proposalIdCounter;
    //Relaciona el id de la propuesta con el contenido de la propuesta (struct Proposal).
    mapping(uint256 => Proposal) public proposals;

    bool public createProposalPermissionCollection1=true;
    bool public createProposalPermissionCollection2=true;
    bool public createProposalPermissionCollection3=true;

    bool public voteProposalPermissionCollection1=true;
    bool public voteProposalPermissionCollection2=true;
    bool public voteProposalPermissionCollection3=true;

    uint8 public votePowerCollection1=1;
    uint8 public votePowerCollection2=2;
    uint8 public votePowerCollection3=3;

    /**
     * -----------------------------------------------------------------------------------------------------
     *                                      EVENTS
     * -----------------------------------------------------------------------------------------------------
     */
    event CreateProposal(
        uint256 indexed proposalId, 
        address indexed creator,
        uint indexed blockNumber);

    event ProposalInfo(
        uint256 indexed proposalId,
        string indexed title,
        string description,
        uint256 indexed deadline,
        uint8 quantityVotesOptions,
        bool executed,
        string[] options,
        bool onChain,
        uint8 onChainParameter,
        uint256 onChainValue
        );


    event VoteProposal(
        uint256 proposalId, 
        address voter, 
        string option,
        uint8 numVotesPerOption);

        //Almacenar en la blockchain

    /**
     * -----------------------------------------------------------------------------------------------------
     *                                      MODIFIERRS
     * -----------------------------------------------------------------------------------------------------
     */

    /**
     * Comprueba que quien llama a la funcion es miembro de la DAO.
     */
     modifier DAOMember(){
        require(ATCNFT.balanceOf(msg.sender) > 0, "NOT DAO MEMBER");
        _;
     }

    /**
     * Comprueba que el rol pasado es valido.
     */
     modifier correctRoleNumber(uint8 _role){
        require(_role >= 1 && _role <= 3, "UNSUPPORTED ROLE");
        _;
     }

     modifier validProposalId(uint256 _proposalId){
        require(_proposalId <= proposalIdCounter && _proposalId > 0, "PROP ID NOT VALID");
        _;
     }

    /**
     * Comprueba los permisos del usuario para crear propuestas.
     */
     modifier checkCreateProposalPermission(){
        uint8 role = getMaxTokenCollection(msg.sender);
        if(role ==  1){
            require(createProposalPermissionCollection1, "CREATE ROLE 1 NOT ALLOWED");
            _;
        }else if(role == 2){
            require(createProposalPermissionCollection2, "CREATE ROLE 2 NOT ALLOWED");
            _;
        }else{
            require(createProposalPermissionCollection3, "CREATE ROLE 3 NOT ALLOWED");
            _;
        }
     }

    /**
     * Comprueba los permisos del usuario para votar propuestas.
     */
     modifier checkVoteProposalPermission(){
        uint8 role = getMaxTokenCollection(msg.sender);
        if(role == 1){
            require(voteProposalPermissionCollection1, "VOTE ROLE 1 NOT ALLOWED");
            _;
        }else if(role == 2){
            require(voteProposalPermissionCollection2, "VOTE ROLE 2 NOT ALLOWED");
            _;
        }else{
            require(voteProposalPermissionCollection3, "VOTE ROLE 3 NOT ALLOWED");
            _;
        }
     }

     /**
     * -----------------------------------------------------------------------------------------------------
     *                                      CREACION PROPUESTAS
     * -----------------------------------------------------------------------------------------------------
     */

    /**
     * Crea una propuesta OffChain. Puede tener mas de una opcion y se puede votar a mas de una opcion.
     * @param _title Titulo de la propuesta.
     * @param _desc Descripcion de la propuesta.
     * @param _quantityVotesOptions Numero de opciones que se pueden votar.
     * @param _options Lista con las opciones de la propuesta.
     */
    function createProposal(string memory _title, string memory _desc,
                             uint8 _quantityVotesOptions, string[] memory _options, uint256 _deadline)
                              DAOMember() checkCreateProposalPermission() public{
        require(!(bytes(_title).length == 0) && 
                    !(bytes(_desc).length == 0), "TITLE AND DESC MUST BE PROVIDED");   
        require(_options.length > 0, "OPTIONS CAN'T BE EMPTY");                             
        // require que compruebe que quantity es menor al tamaño del array de opciones.
        require(_quantityVotesOptions < _options.length && _quantityVotesOptions > 0, "NOT VALID QUANTITY VOTES OPTIONS");
        

        proposalIdCounter++;
        Proposal storage proposal = proposals[proposalIdCounter];
        proposal.proposalId = proposalIdCounter;
        proposal.title = _title;
        proposal.description = _desc;
        proposal.deadline = block.timestamp + _deadline;
        proposal.quantityVotesOptions = _quantityVotesOptions;
        // proposal.totalVoters = 0;
        proposal.executed = false;
        // proposal.proposalCreator = msg.sender;

        proposal.onChain = false;
        proposal.onChainParameter = 0;
        proposal.onChainValue = 0;

        //Recorremos el array de opciones y establecemos a cada opción el numero de votos = 0
        for(uint8 i = 0; i < _options.length; i++){
            proposal.optionsCode[i]=_options[i];
            proposal.optionsVotes[i]=0;
        }

        // for (uint i = 0; i < _options.length; i++) {
        //     proposal.optionsAndVotes[_options[i]] = 0;
        // }

        proposal.optionsNumber = uint8(_options.length);

        proposal.blockNumber = block.number;


        emit CreateProposal(proposal.proposalId,msg.sender,proposal.blockNumber);
        emit ProposalInfo(
            proposal.proposalId, 
            _title,
            _desc,
            proposal.deadline,
            _quantityVotesOptions,
            false,
            _options,
            proposal.onChain,
            proposal.onChainParameter,
            proposal.onChainValue);
    }

    function getProposalBlockNumber(uint256 _proposalId) public view returns (uint) { return proposals[_proposalId].blockNumber; }


    /**
     * Crea una propuesta de tipo OnChain. Modifica el valor de un parametro de la DAO.
     * Son propuestas binarias. Dos opciones SI o NO.
     * @param _title Titulo de la propuesta.
     * @param _desc Descripcion de la propuesta.
     * @param _parameter Id del parametro a modificar.
     * @param _value Nuevo valor que asignar al parametro.
     */
    function createOnChainProposal(string memory _title, string memory _desc, uint8 _parameter, uint256 _value, uint256 _deadline) DAOMember() checkCreateProposalPermission() public{
        proposalIdCounter++;
        Proposal storage proposal = proposals[proposalIdCounter];
        proposal.proposalId = proposalIdCounter;
        proposal.title = _title;
        proposal.description = _desc;
        proposal.deadline = block.timestamp + _deadline;
        // proposal.totalVoters = 0;
        proposal.executed = false;
        // proposal.proposalCreator = msg.sender;
        
        proposal.onChain = true;
        proposal.onChainParameter = _parameter;
        proposal.onChainValue = _value;

        // proposal.optionsCode[0] = "NO";
        // proposal.optionsCode[1] = "YES";

        proposal.optionsCode[0] = "NO";
        proposal.optionsCode[1] = "YES";

        proposal.optionsVotes[0] = 0;
        proposal.optionsVotes[1] = 0;

        proposal.optionsNumber = 2;
    }

    /**
     * -----------------------------------------------------------------------------------------------------
     *                                      VOTACION PROPUESTAS
     * -----------------------------------------------------------------------------------------------------
     */


    /**
     * Permite votar opciones dentro de una propuesta.
     * @param _proposalId Identificador de la propuesta.
     * @param _votes Array con los identificadores de los votos.
     */
    function voteProposal(uint256 _proposalId, uint8[] memory _votes) DAOMember()  validProposalId(_proposalId) public {
        //Requires.
        //Comprueba que la propuesta exista.
        // require(_proposalId <= proposalIdCounter && _proposalId > 0 , "PROP ID NOT VALID");

        Proposal storage proposal = proposals[_proposalId];

        //Comprueba que la cantidad de votos que se quieren emitir sea correcta.
        require(_votes.length <= proposal.quantityVotesOptions && _votes.length > 0,"NOT VALID QUANTITY OPTIONS");
        //Comprueba que la propuesta no haya sido ejecutada.
        require(! proposal.executed, "PROP EXECUTED");
        //Comprueba que el usuario no haya votado ya.
        require(!hasAddressVoted(_proposalId), "CANNOT VOTE 2 TIMES");
        //Comprueba que la propuesta se encuntra dentro de plazo
        require( proposal.deadline > block.timestamp, "PROP OUT OF DATE");
        //Comprueba que los indices de opciones recibidos son validos.
        //Si la propuesta tiene 3 opciones, 1 VALID, 6 INVALID.
        for(uint8 i = 0; i < _votes.length; i++){
            require( _votes[i] <= proposal.optionsNumber - 1 && _votes[i] >= 0, "OPTION INDEX NOT VALID");
        }
      
        //Obtener el rol del usuario para determinar los votos que van a ser emitidos.
        uint8 maxTokenCollection = getMaxTokenCollection(msg.sender);
        uint8 nVotes;
        if (maxTokenCollection == 1){
            nVotes = votePowerCollection1;
        }
        else if (maxTokenCollection == 2) {
            nVotes = votePowerCollection2;
        }
        else if (maxTokenCollection == 3) {
            nVotes = votePowerCollection3;
        }

        //Computar el numero de votos.
        // uint8 totalVotes = 0;
        //Array que contendra los votos emitidos a cada opcion.
        // uint8[] memory votesPerOption = new uint8[](_votes.length);

        //Se itera sobre los votos recibidos por parametros
        for(uint8 i = 0; i < _votes.length; i++){
            //Se suman los votos a la opcion que corresponde
            proposal.optionsVotes[_votes[i]] += nVotes;
            //Se establece que el usuario ha emitido nVotes a esa opcion.
            // votesPerOption[i] = nVotes;
            // TODO: emitir un evento de votacion adecuado

            emit VoteProposal(_proposalId, msg.sender, proposal.optionsCode[_votes[i]], nVotes);
            
        }
        //Cantidad total de votos emitidos por el usuario.
        // totalVotes = nVotes * uint8(_votes.length);

        //Relaciona el id del usuario dentro de la propuesta con su address.
        proposal.voters.push(msg.sender);
        // //Relaciona el id del usuario dentro de la propuesta con el numero total de votos emitidos.
        // proposal.votesFromVoter[proposal.totalVoters] = totalVotes;

        // //Relaciona el id del usuario dentro de la propuesta con un array con las opciones que ha votado.
        // proposal.votersOptions[proposal.totalVoters] = _votes;
        // //Relaciona el id del usuarios dentro de la propuesta con un array con los votos que ha emitido a cada opcion.
        // proposal.votersOptionsVotes[proposal.totalVoters] = votesPerOption;

        // proposal.totalVoters += 1;
    }

    /**
     * Comprueba si el msg.sender ha votado en la propuesta.
     * @param _proposalId Identificador de la propuesta que se va a votar.
     */
    function hasAddressVoted(uint256 _proposalId) validProposalId(_proposalId) internal view returns (bool){
        Proposal storage proposal = proposals[_proposalId];
        for(uint8 i = 0; i < proposal.voters.length; i++){
            if(proposal.voters[i] == msg.sender){
                return true;
            }
        }
        return false;
    }

    /**
     * -----------------------------------------------------------------------------------------------------
     *                                      LECTURA PROPUESTAS
     * -----------------------------------------------------------------------------------------------------
     */

    /**
     * Devuelve un array con los id de los ATCNFT que posee el usuario.
     * @param _owner address del usuario del que se consultan los ATCNFT.
     */
    function getTokensFromOwner(address _owner) public view returns (uint256[] memory){
        return ATCNFT.getTokenIDFromOwner(_owner);
    }

    /**
     * Devuelve true en caso de que el usuario pasado como parametro sea propietario de un NFT de la colección numCollection. En caso contrario devuelve false.
     * @param _collection Id/Numero de la coleccion que se quiere comprobar (1,2,3)
     */
    function isTokenCollectionHolder(uint8 _collection) /*DAOMember()*/ public view returns(bool){
        //Obtiene un array con los datos de todos los NFTs que pertenecen al usuario.
        uint256[] memory tokens = ATCNFT.getTokenIDFromOwner(msg.sender);
        for(uint256 i = 0; i < tokens.length; i++){
            //Comprueba 1 a 1 el tipo de los tokens, en caso de pertenecer a la coleccion numCollection devuelve true
            if(ATCNFT.getTypeOfToken(tokens[i]) == _collection){
                return true;
            }
        }
        //Si acaba el loop y no ha devuelto true, significa que no tiene ningun NFT de la coleccion numCollection, por lo tanto devuelve false
        return false;
    }

    /**
     * Devuelve un objeto ReturnProposal con todo la informacion de una propuesta.
     * @param _proposalId Id de la propuesta que se quiere obtener.
     */
    function getProposal(uint256 _proposalId) validProposalId(_proposalId) public view returns(ReturnProposal memory){
        // require(_proposalId <= proposalIdCounter, "PROP ID NOT VALID");

        Proposal storage proposal = proposals[_proposalId];
        ReturnProposal memory returnProposal;

        returnProposal.proposalId = proposal.proposalId;
        // returnProposal.deadline = proposal.deadline;
        // returnProposal.title = proposal.title;
        // returnProposal.description = proposal.description;
        // returnProposal.executed = proposal.executed;
        // returnProposal.quantityVotesOptions = proposal.quantityVotesOptions;
        // returnProposal.proposalCreator = proposal.proposalCreator;

        // returnProposal.onChain =  proposal.onChain;
        // returnProposal.onChainParameter =  proposal.onChainParameter;
        // returnProposal.onChainValue =  proposal.onChainValue;

        returnProposal.optionsCode = new string[](proposal.optionsNumber);
        returnProposal.optionsVotes = new uint8[](proposal.optionsNumber);

        // returnProposal.voters = new address[](proposal.totalVoters);

        // returnProposal.votesFromVoter = new uint8[](proposal.totalVoters);

        // returnProposal.votersOptions = new uint8[][](proposal.totalVoters);
        // returnProposal.votersOptionsVotes = new uint8[][](proposal.totalVoters);

        for(uint8 i = 0; i < proposal.optionsNumber; i++){
            returnProposal.optionsCode[i] = proposal.optionsCode[i];
            returnProposal.optionsVotes[i] = proposal.optionsVotes[i];
        }
        // for(uint8 i = 0; i < proposal.totalVoters; i++){
        //     returnProposal.voters[i] = proposal.voters[i];
        //     returnProposal.votesFromVoter[i] = proposal.votesFromVoter[i];
        //     returnProposal.votersOptions[i]=proposal.votersOptions[i];
        //     returnProposal.votersOptionsVotes[i]=proposal.votersOptionsVotes[i];
        // }
        
        return returnProposal;
    }

    /**
     * A partir de un usuario, nos devuelve el valor de la colección de mayor rol que tiene este usuario.
     * @param _user address del usuario a obtener su coleccion mas alta.
     */
    function getMaxTokenCollection(address _user) public view returns (uint8) {
        //Obtiene un array con los datos de todos los NFTs que pertenecen al usuario.
        uint256[] memory tokenIds = ATCNFT.getTokenIDFromOwner(_user);
        //Inicializa la variable maxToken a 0, que nos serivra para saber el NFT de mayor grado que pertenece al usuario
        uint8 maxToken = 0;
        //Comprueba 1 a 1 el tipo de los tokens, al acabar queda almacenado en la variable maxToken el valor de
        // la coleccion de mayor grado
        for (uint256 i=0;i<tokenIds.length;i++) {
            uint256 idActual = tokenIds[i];
            if (ATCNFT.getTypeOfToken(idActual) == 1 && maxToken < 1) maxToken = 1;
            else if (ATCNFT.getTypeOfToken(idActual) == 2 && maxToken < 2) maxToken = 2;
            else if (ATCNFT.getTypeOfToken(idActual) == 3) return 3;
        }
        //require(maxToken == 1 , "holderOfTokenCollection - No tiene token.");
        //Finalmente devuelve el valor de la colección de mayor grado que tiene el usuario
        return maxToken;
    }

    function isProposalActive(uint256 _proposalId) public view returns(bool){
        return (block.timestamp < proposals[_proposalId].deadline);
    }

    function countActiveProposals() internal view returns(uint256){
        uint256 activeProposals = 0;
        for(uint256 i = 1; i <= proposalIdCounter; i++){
            if(isProposalActive(i)){
                activeProposals++;
            }
        }
        // console.log("countActiveProposals - Propuestas activas: %s", activeProposals);
        return activeProposals;
    }

    function getActiveProposalsIds() public view returns(uint256[] memory){
        uint256 activeProposalsNumber = countActiveProposals();
        uint256[] memory activeProposalsIds = new uint256[](activeProposalsNumber);
        uint256 index = 0;
        for(uint256 i = 1; i <= proposalIdCounter; i++){
            if(isProposalActive(i)){
                activeProposalsIds[index] = i;
                index++;
            }
        }
        return activeProposalsIds;
    }

    function getInactiveProposalsIds() public view returns(uint256[] memory){
        uint256 inactiveProposalsNumber = proposalIdCounter - countActiveProposals();
        // console.log("getInactiveProposalsIds - Propuestas inactivas: %s",inactiveProposalsNumber);
        if(inactiveProposalsNumber > 0){
            uint256[] memory inactiveProposalsIds = new uint256[](inactiveProposalsNumber);
            uint256 index = 0;
            for(uint256 i = 1; i <= proposalIdCounter; i++){
                if(!isProposalActive(i)){
                    inactiveProposalsIds[index] = i;
                    index++;
                }
            }
            return inactiveProposalsIds;
        }
        return new uint256[](0);
    }     

    /**
     * -----------------------------------------------------------------------------------------------------
     *                                      EJECUTAR PROPUESTA ONCHAIN
     * -----------------------------------------------------------------------------------------------------
     */

    /**
     * Para las propuestas OnChain, ejecuta el cambio de valor del parametro votado.
     * @param _proposalId Id de la propuesta que se quiere ejecutar.
     */
    function executeProposalOnChain(uint256 _proposalId) validProposalId(_proposalId) public{
        Proposal storage proposal = proposals[_proposalId];
        //comprobar q es on chain
        require(proposal.onChain,"NOT ONCHAIN PROPOSAL");
        //comprobar q el plazo ha terminado
        require(proposal.deadline <= block.timestamp, "VOTATION TIME HAS NOT FINISHED");
        //comprobar que no ha sido ejecutada ya
        require(!proposal.executed,"PROP ALREADY EXECUTED");
        //comprobar que el creador de la propuesta es quien la ejecuta
        // require(msg.sender == proposal.proposalCreator, "ONLY PROP CREATOR CAN EXECUTE");

        //comprobar que la votacion ha sido afirmativa
        // if(proposal.optionsVotes[1] > proposal.optionsVotes[0]){
        //     setDAOParameter(proposal.onChainParameter, proposal.onChainValue);
        // }


        proposal.executed = true;
    }

    /**
     * Modifica un parametros de gobernanza de la DAO. Solo deberia ser llamado desde la propia DAO.
     * 0 => false; 1 => true;
     * @param _parameter Indica el parametro a modificar. Esta codificado.
     * @param _value Nuevo valor que se quiere dar al parametro.
     */
    function setDAOParameter(uint8 _parameter, uint256 _value) internal {
        //TODO: incluir requires que aseguren que los valores son correctos
        if(_parameter >= 4 && _parameter <= 9){
            require(_value == 0 || _value == 1, "VALUE NOT VALID");
        }

        //Vote Power Collection 1
        if(_parameter == 1){
            votePowerCollection1 = uint8(_value);
        }
        //Vote Power Collection 2
        else if(_parameter == 2){
            votePowerCollection2 = uint8(_value);
        }
        //Vote Power Collection 3
        else if(_parameter == 3){
            votePowerCollection3 = uint8(_value);
        }
        //Create Proposal Collection 1
        else if(_parameter == 4){
            createProposalPermissionCollection1=_value==1?true:false;
        }
        //Create Proposal Collection 2
        else if(_parameter == 5){
            createProposalPermissionCollection2=_value==1?true:false;
        }
        //Create Proposal Collection 3
        else if(_parameter == 6){
            createProposalPermissionCollection3=_value==1?true:false;
        }
        //Vote Proposal Collection 1
        else if(_parameter == 7){
            voteProposalPermissionCollection1=_value==1?true:false;
        }
        //Vote Proposal Collection 2
        else if(_parameter == 8){
            voteProposalPermissionCollection2=_value==1?true:false;
        }
        //Vote Proposal Collection 3
        else if(_parameter == 9){
            voteProposalPermissionCollection3=_value==1?true:false;
        }
        //NFT Cooldown
        //TODO: decidir como modificar el cooldown; por ID, por coleccion,...
        else if(_parameter == 10){
            // IATCNFT.setTokenCooldown();
        }
    }

    /**
     * -----------------------------------------------------------------------------------------------------
     *                                      GESTIONAR FONDOS ATCC
     * -----------------------------------------------------------------------------------------------------
     */

    /**
     * Retira los fondos asociados a la DAO a la direccion owner().
     */
    function withdrawATCCBalance() onlyOwner public {
        ATCC.transfer(owner(), ATCC.balanceOf(address(this)));
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Proposals{

    /**
     * Enum con los posibles estados de una propuesta
     *  ACTIVE: La propuesta se ha creado y se esta votando.
     *  SUCCEED: La propuesta ha sido votada y aceptada.
     *  EXECUTED: La propuesta aceptada ha sudo ejecutada.
     *  FAILED: La propuesta ha sido votada y rechazada.
     */
    enum ProposalState{
        ACTIVE, 
        SUCCEED, 
        EXECUTED, 
        FAILED
    }
    
    /**
     * PROPOSAL
     * Struct que nos servira para almacenar los datos de cada propuesta.
     */
    struct Proposal{
        //Id de la propuesta.
        uint256 proposalId;
        //Titulo de la propuesta.
        string title;
        //Descripcion de la propuesta.
        string description;
        //Limite de tiempo de la votacion.
        uint256 deadline;
        //Cantidad de opciones que el usuario puede votar en la propuesta.
        uint8 quantityVotesOptions;
        //Cantidad de opciones que contiene la propuesta.
        uint8 optionsNumber;
        //Cantidad total de votantes/participantes en la propuesta.
        uint8 totalVoters;
        //Indica si la propuesta ha sido ejecutada.
        bool executed;
        //Address del creador de la propuesta.
        //address proposalCreator;

        //añadir options => numVotesOptions
        //mapping(string => uint8) optionsAndVotes;

        //Relaciona cada identificador de opcion con el texto de la opcion.
        mapping(uint8 => string) optionsCode;
        //Relaciona cada identificador de opcion con el numero de votos.
        mapping(uint8 => uint8) optionsVotes;

        //Cambio por ->
        // string[] options;

        //@author: Ivan
        // //Relaciona cada indentificador de votante (uint8) con la address del votante.
        address[] voters;
        // //Relaciona cada identificador de votante con el total de votos emitidos.
        // mapping(uint8 => uint8) votesFromVoter;
        // //Booleanos que determinan si un rol puede crear propouestas.
        // // true => pueden. false => no pueden.

        //Se puede obtener por el event VoteProposal con el address i los votos

        //@author: Isa
        //Relaciona el id del address (dentro de la propuesta) con las opciones que vota.
        // mapping(uint8 => uint8[]) votersOptions;
        // //Relaciona el id del address (dentro de la propuesta) con los votos a cada opcion.
        // mapping(uint8 => uint8[]) votersOptionsVotes;


        //Se puede conseguir con event VoteProposal (address, _votes, numVotes)


        //Determina si la propuesta es onChain.
        bool onChain;
        //Determina el parametro de la DAO a ser modificado.
        uint8 onChainParameter;
        //Nuevo valor para el parametro.
        uint256 onChainValue;

        uint blockNumber;

    }

     /**
     * Struct utilizado para devolver la informacion de la propuesta
     */
    struct ReturnProposal{
        uint256 proposalId;
        // string title;
        // string description;
        // uint256 deadline;
        // uint8 quantityVotesOptions;
        // bool executed;
        // address proposalCreator;

        uint8[] optionsVotes;
        string[] optionsCode;
        // address[] voters; //--> comentar ? (no se usa en el frontend)

        // uint8[] votesFromVoter;
        // uint8[][] votersOptions;
        // uint8[][] votersOptionsVotes;
        
        // bool onChain;
        // uint8 onChainParameter;
        // uint256 onChainValue;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IATCNFT is IERC721{

     function getTypeOfToken(uint256 _tokenID) external view returns(uint8);

     function balanceOf(address _owner) external view returns(uint256);

     function getTokenIDFromOwner(address _owner) external view returns(uint256[] memory);

     function setTokenCooldown(uint256 _tokenId, uint256 _cooldown) external;

}