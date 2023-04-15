/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

//SPDX-License-Identifier: MIT
//Título: Contrato Inteligente Algorithm X basado en (Privacidad) de transacciones ofuscadas
//Auditado por AlgorithmXlabs
//Title: Algorithm X Smart Contract based on (Privacy) obfuscated transactions
//Audited by AlgorithmXlabs
//this smart contract was inspired by nick szabo
/**The AlgorithmX team has resigned from the tokens, which will now be managed by the 
TokenomicsAlgorithmX contract. 
This is done to establish clear and transparent practices in the distribution and management 
of tokens, avoiding any possibility of fraud.
The predefined tokenomics structure in the TokenomicsAlgorithmX contract establishes 
percentages and lock-up times to ensure a fair and appropriate distribution of tokens, 
in accordance with the rules and logic set forth in the contract. 
This ensures that token management is carried out transparently and in line with the project's 
objectives and principles.**/
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0; //

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: managerfounds.sol


// Título: Contrato Inteligente de Gestión de Tokens para Algorithm X (Privacidad)
//Auditado por AlgorithmXlabs
pragma solidity ^0.8.0;



contract TokenomicsAlgorithmX is Ownable {
    IERC20 private _token; 
    //variables declaration address wallets
    address private tokenContractAddress;
    address public airdropWallet = 0x66412478f0f0b435511a2E5B7fbBBC35006fEd23; // Airdrop wallet address
    address public equipoWallet = 0xCfd39FAFD3D39d20d32CBf334DD76c641e64b349; // Team wallet address
    address public reservaWallet = 0x80b3524c34a9E95379eF391D2944E915FBdeb4a7; // Backup wallet address
    address public marketingWallet = 0x4082614E6C609CE21c75660AaF66B06b726b0bBD; // Marketing wallet address
    address public salePublicaWallet1 = 0xaf34b77B25289a3b8700eF363d0AB568BE01456c; // Address of public sale wallet 1
    address public salePublicaWallet2 = 0xaf34b77B25289a3b8700eF363d0AB568BE01456c; // Address of public sale wallet 2 block (180 days)
    //variables precentage token distribution
    uint256 public airdropPercentage = 12; // Percentage of tokens for the airdrop
    uint256 public equipoPercentage = 8; // Percentage of tokens for the team block 1 years
    uint256 public reservaPercentage = 10; // Percentage of tokens for the reserve
    uint256 public marketingPercentage = 10; // Percentage of tokens for  marketing
    uint256 public ventaPublicaPercentage1 = 30; // Percentage of tokens for  sale públic 1
    uint256 public ventaPublicaPercentage2 = 30; // Percentage of tokens for  sale públic  2
   //lock variables
    uint256 public teamTokensLockedUntil; 
    uint256 public airdropTokensLockedUntil; 
    uint256 public saleTwoTokensLockedUntil;
    
    uint256 public _totalSupply; 
   
    
    event TokensAssigned(address wallet, uint256 amount);
    event TokensReceived(address indexed from, uint256 amount);
    // Constructor del contract
    constructor(address tokenAddress) {
        _token = IERC20(tokenAddress);
    }
    
   // Function to assign tokens to public sale 1 (immediate)
    function SaleOne() external onlyOwner {
        uint256 totalSupply = _token.totalSupply();
        uint256 tokensVentaPublica1 = (totalSupply * ventaPublicaPercentage1) / 100;
        require(_token.transfer(salePublicaWallet1, tokensVentaPublica1), "Error en la transferencia de tokens de venta publica 1");
    }
    
    // Function to assign tokens for public sale 2 (Locked for 180 days)
    function SaleTwo() public onlyOwner {
    require(saleTwoTokensLockedUntil == 0, "Los tokens de SaleTwo ya han sido asignados."); // Se verifica que los tokens de SaleTwo no hayan sido asignados previamente
    uint256 saleTwoTokens = (_totalSupply * ventaPublicaPercentage2) / 100; // Se calcula la cantidad de tokens para SaleTwo
    _token.transfer(equipoWallet, saleTwoTokens); // Se transfieren los tokens a SaleTwo
    saleTwoTokensLockedUntil = block.timestamp + (180 days); // Se establece el tiempo de bloqueo de los tokens de SaleTwo a 1 año (en segundos)
    }

    // Function to assign tokens to the airdrop (Locked 180 days)
      function Airdrop() public onlyOwner {
        require(airdropTokensLockedUntil == 0, "Los tokens del airdrop ya han sido asignados."); // Se verifica que los tokens del airdrop no hayan sido asignados previamente
        uint256 airdropTokens = (_totalSupply * airdropPercentage) / 100; // Se calcula la cantidad de tokens para el airdrop
        _token.transfer(airdropWallet, airdropTokens); // Se transfieren los tokens al airdrop
        airdropTokensLockedUntil = block.timestamp + (180 days); // Se establece el tiempo de bloqueo de los tokens del airdrop a 180 días (en segundos)
    }

   // Function to assign tokens to the team (Blocked 365 days)
   function Team() public onlyOwner {
   require(teamTokensLockedUntil == 0, "Los tokens del equipo ya han sido asignados."); // Se verifica que los tokens del equipo no hayan sido asignados previamente
   uint256 teamTokens = (_totalSupply * equipoPercentage) / 100; // Se calcula la cantidad de tokens para el equipo
   _token.transfer(equipoWallet, teamTokens); // Se transfieren los tokens al equipo
   teamTokensLockedUntil = block.timestamp + (365 days); // Se establece el tiempo de bloqueo de los tokens del equipo a 1 año (en segundos)
  
   }

    // Function to assign tokens to the pool
    function Reserve() external onlyOwner {
        uint256 totalSupply = _token.totalSupply();
        uint256 tokensreservaWallet = (totalSupply * airdropPercentage) / 100; 
        require(_token.transfer(reservaWallet,tokensreservaWallet), "La direccion de la billetera de reserva no ha sido establecida");

       
    }

    // Function to assign tokens to marketing
    function Marketing() external onlyOwner {
       uint256 totalSupply = _token.totalSupply();
        uint256 tokensmarketingWallet = (totalSupply * airdropPercentage) / 100; 
        require(_token.transfer(marketingWallet,tokensmarketingWallet), "La direccion de la billetera de marketing no ha sido establecida");

    }
   
   // Function to change the address of the airdrop wallet
   function setAirdropWallet(address newWallet) external onlyOwner {
       require(newWallet != address(0), "La nueva direccion de billetera no puede ser cero");
       airdropWallet = newWallet;
    }

   // Function to change the team wallet address
    function setEquipoWallet(address newWallet) external onlyOwner {
       require(newWallet != address(0), "La nueva direccion de billetera no puede ser cero");
       equipoWallet = newWallet;
    } 

  // Function to change the address of the reserve wallet
    function setReservaWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "La nueva direccion de billetera no puede ser cero");
        reservaWallet = newWallet;
    }

   // Function to change the address of the marketing wallet
   function setMarketingWallet(address newWallet) external onlyOwner {
       require(newWallet != address(0), "La nueva direccion de billetera no puede ser cero");
       marketingWallet = newWallet;
    }

  // Function to change the address of the public sale wallet 1
   function setVentaPublicaWallet1(address newWallet) external onlyOwner {
      require(newWallet != address(0), "La nueva direccion de billetera no puede ser cero");
      salePublicaWallet1 = newWallet;
    }

   // Function to change the address of the public sale wallet 2
   function setVentaPublicaWallet2(address newWallet) external onlyOwner {
       require(newWallet != address(0), "La nueva direccion de billetera no puede ser cero");
       salePublicaWallet2 = newWallet;
    }

    
    // Internal function to calculate a percentage of an amount
    function calculatePercentage(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        return (amount * percentage) / 100;
    }

    // Function to receive tokens
    function receiveTokens(address token, uint256 amount) external onlyOwner{
        require(token == tokenContractAddress, "Invalid token"); // Verifica que el token recibido sea el esperado
        require(amount > 0, "Invalid amount"); // Verifica que la cantidad de tokens sea mayor a 0
        
       // Transfer the tokens from the sender to this contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        // Emit token receive event
        emit TokensReceived(msg.sender, amount);
        
    }
    
   // Function to set the address of the token contract
    function setTokenContractAddress(address _tokenContractAddress) external onlyOwner {
        require(_tokenContractAddress != address(0), "Invalid address");
        tokenContractAddress = _tokenContractAddress;
    }


     function pause() public onlyOwner {
        pause();
    }

    function unpause() public onlyOwner {
        unpause();
    }

}