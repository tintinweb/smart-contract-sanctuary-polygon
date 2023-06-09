// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";

contract Casino is Ownable{

    event RouletteGame (
        uint NumberWin,
        bool result,
        uint tokensEarned
    );

    ERC20 private token;
    address public tokenAddress;

    function prixTokens(uint256 _numTokens) public pure returns (uint256){
        return _numTokens * (0.001 ether);
    }

    function tokenBalance(address _of) public view returns (uint256){
        return token.balanceOf(_of);
    }
    constructor(){
        token =  new ERC20("Casino", "CAS");
        tokenAddress = address(token);
        token.mint(1000000);
    }

    // Balance en ether du Smart Contract
    function balanceEthersSC() public view returns (uint256){
        return address(this).balance / 10**18;
    }

    function getAdress() public view returns (address){
        return address(token);

    }

     function achatTokens(uint256 _numTokens) public payable{
        // Enregistrement de l'utilisateur
        // Détermination du coût des jetons à acheter
        // Évaluation de l'argent que le client paie pour les jetons
        require(msg.value >= prixTokens(_numTokens), "Achetez moins de jetons ou payez avec plus dethers.");
        // Création de nouveaux jetons en cas de manque d'approvisionnement suffisant
        if  (token.balanceOf(address(this)) < _numTokens){
            token.mint(_numTokens*100000);
        }
        //Retour d'argent excédentaire
        //Le contrat intelligent renvoie le montant restant.
        payable(msg.sender).transfer(msg.value - prixTokens(_numTokens));
        //Envoi des jetons au client/utilisateur.
        token.transfer(address(this), msg.sender, _numTokens);
    }

    // Remboursement de tokens au Smart Contract
    function retirerTokens(uint _numTokens) public payable {
      // Le nombre de tokens doit être supérieur à 0
        require(_numTokens > 0, "Vous devez renvoyer un nombre de jetons superieur a 0");
        // L'utilisateur doit prouver qu'il possède les tokens qu'il souhaite rembourser
        require(_numTokens <= token.balanceOf(msg.sender), "Vous n'avez pas les jetons que vous souhaitez retourner.");
        // L'utilisateur transfère les tokens au Smart Contract
        token.transfer(msg.sender, address(this), _numTokens);
      // Le Smart Contract envoie les ethers à l'utilisateur
        payable(msg.sender).transfer(prixTokens(_numTokens)); 
    }

    struct Bet {
        uint tokensBet;
        uint tokensEarned;
        string game;
    }

    struct RouleteResult {
        uint NumberWin;
        bool result;
        uint tokensEarned;
    }

    mapping(address => Bet []) historiquedesparis;

    function retirarEth(uint _numEther) public payable onlyOwner {
            // Le nombre de tokens doit être supérieur à 0
        require(_numEther > 0, "Il est necessaire de rendre un nombre de jetons superieur a 0.");
       // L'utilisateur doit prouver qu'il possède les tokens qu'il souhaite rembourser
        require(_numEther <= balanceEthersSC(), "Tu nas pas les jetons que tu souhaites retirer.");
        // Transfère les ethers demandés au propriétaire du smart contract
        payable(owner()).transfer(_numEther);
    }

    function tonhistorique(address _owner) public view returns(Bet [] memory){
        return historiquedesparis[_owner];
    }

    function jouerroulette(uint _start, uint _end, uint _tokensBet) public{
        require(_tokensBet <= token.balanceOf(msg.sender));
        require(_tokensBet > 0);
        uint random = uint(uint(keccak256(abi.encodePacked(block.timestamp))) % 14);
        uint tokensEarned = 0;
        bool win = false;
        token.transfer(msg.sender, address(this), _tokensBet);
        if ((random <= _end) && (random >= _start)) {
            win = true;
            if (random == 0) {
                tokensEarned = _tokensBet*14;
            } else {
                tokensEarned = _tokensBet * 2;
            }
            if  (token.balanceOf(address(this)) < tokensEarned){
            token.mint(tokensEarned*100000);
            }
            token.transfer( address(this), msg.sender, tokensEarned);
        }
            addHistorique("Roulete", _tokensBet, tokensEarned, msg.sender);
            emit RouletteGame(random, win, tokensEarned);
    }

    function addHistorique(string memory _game, uint _tokensBet,  uint _tokenEarned, address caller) internal{
        Bet memory pari = Bet(_tokensBet, _tokenEarned, _game);
        historiquedesparis[caller].push(pari);
    }

    }

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
pragma solidity ^0.8.4;

interface IERC20 {

    // Renvoie le nombre de tokens existants.
    function totalSupply() external view returns (uint256);

    // Renvoie la quantité de jetons qu'un compte possède.
    function balanceOf(address account) external view returns (uint256);

   /* Effectue un transfert de jetons à un destinataire.
    Renvoie une valeur booléenne indiquant si l'opération a réussi.
    Émet un événement {Transfer}. */
    function transfer(address from, address to, uint256 amount) external returns (bool);

    /* Est émis lorsqu'un transfert de jetons est effectué.
   Notez que value peut être nul. */
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// Contrat intelligent des jetons ERC20
contract ERC20 is IERC20 {

// Structures de données
    mapping(address => uint256) private _balances;
    
    // Variables
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address public owner;

    modifier onlyOwner(address _owner) {
        require(_owner == owner, "Vous netes pas owner");
        _;
    }

    /* / Définit la valeur du nom et du symbole du jeton.
   La valeur par défaut de {decimals} est de 18. Pour sélectionner une valeur différente pour
   {decimals} doit être remplacé. / */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
    }

    //  Renvoie le nom du jeton.
    function name() public view virtual returns (string memory) {
        return _name;
    }

// Renvoie le symbole du jeton, généralement une version abrégée du nom.
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

   /* Renvoie le nombre de décimales utilisées pour obtenir sa représentation utilisateur.
   Par exemple, si decimals est égal à 2, un solde de 505 jetons devrait
   être affiché à l'utilisateur comme 5,05 (505 / 10 ** 2).
   Les jetons ont généralement une valeur de 18, imitant la relation entre
   Ether et Wei. C'est la valeur qu'utilise {ERC20}, sauf si cette fonction est
   annulée. */
    function decimals() public view virtual returns (uint8) {
        return 0;
    }

    // totalSupply
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    // retourne la balance
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /* transfer
    Requisitos:
    to ne peut pas être l'adresse zéro.
la personne qui exécute doit avoir un solde d'au moins amount. */ 
    function transfer(address from,address to, uint256 amount) public virtual override returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    function mint(uint256 amount) public virtual onlyOwner(msg.sender) returns (bool) {
        _mint(msg.sender, amount);
        return true;
    }

    /*/* Déplacer  des jetons de l'expéditeur sender au destinataire recipient.
    Cette fonction interne est équivalente à {transfer}, et peut être utilisée pour
    par exemple, mettre en œuvre des frais automatiques de jetons, etc.
    Émet un événement {Transfer}.
    Exigences:
    
from et to ne peuvent pas être des adresses zéro.
from doit avoir un solde d'au moins amount. */ 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    /* Crée des jetons "amount" et les attribue à un "account", augmentant
    l'offre totale.
    Émet un événement {Transfer} avec "from" en tant qu'adresse zéro.
    Exigences:
    
account ne peut pas être l'adresse zéro. */
    function _mint(address account, uint256 amount) internal virtual{
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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