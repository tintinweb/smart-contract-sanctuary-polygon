/**
 *Submitted for verification at polygonscan.com on 2022-06-21
*/

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/CartridgeMetadata.sol


// HashUp Contracts V1
pragma solidity ^0.8.0;

 
/**
 * @dev HashUp implementation of ERC20 Metadata that suits HashupCartridge.
 */
contract CartridgeMetadata is Ownable {
	// Cartridge name
	string private _name;
 
	// Cartridge symbol
	string private _symbol;
 
	// Cartridge color
	string private _color;
 
	// Other Metadata URL
	string private _metadataUrl;
 
	/**
	 * @dev Initializes the Cartridge Contract and sets
	 * correct color for provided supply and metadata.
	 */
	constructor(
		string memory name_,
		string memory symbol_,
		string memory metadataUrl_,
		uint256 totalSupply_
	) {
		_name = name_;
		_symbol = symbol_;
		_metadataUrl = metadataUrl_;
		_color = _getColorForSupply(totalSupply_);
	}
 
	/**
	 * @dev Updates current URL to metadata object that stores configuration of visuals,
	 * descriptions etc. that will appear while browsing on HashUp ecosystem.
	 *
	 * NOTE: We use IPFS by default in HashUp.
	 *
	 * Requirements:
	 * - the caller must be creator
	 */
	function setMetadata(string memory newMetadata) public onlyOwner {
		_metadataUrl = newMetadata;
	}
 
	/**
	 * NOTE: ERC20 Tokens usually use 18 decimal places but our
	 * CEO said it's stupid and we should use 2 decimals
	 */
	function decimals() public pure returns (uint8) {
		return 2;
	}
 
	/**
	 * @dev Returns the color of cartridge. See {_getColorForSupply}
	 * function for details
	 */
	function color() public view returns (string memory) {
		return _color;
	}
 
	/**
	 * @dev Returns the name of the cartridge.
	 */
	function name() public view returns (string memory) {
		return _name;
	}
 
	/**
	 * @dev Returns the symbol of the cartridge.
	 */
	function symbol() public view returns (string memory) {
		return _symbol;
	}
 
	/**
	 * @dev Returns the URL of other cartridge metadata
	 */
	function metadataUrl() public view returns (string memory) {
		return _metadataUrl;
	}
 
	/**
	 * @dev Returns Cartridge color for specified supply. There are three types
	 * of cartridges based on a totalSupply (numbers without including decimals)
	 * 0 - 133.700 => Gold Cartridge
	 * 133.701 - infinity => Gray Cartridge
	 *
	 * NOTE: Color doesn't affect Cartridge Token logic, it's used for display
	 * purposes so we can simplify token economics visually.
	 */
	function _getColorForSupply(uint256 supply)
		private
		pure
		returns (string memory color)
	{
		if (supply <= 133_700 * 10**decimals()) {
			return "gold";
		} else {
			return "gray";
		}
 
	}
}
 
// File: contracts/HashupCartridge.sol


// HashUp Contracts V1
pragma solidity ^0.8;



/**
_________  ___  ___  _______                                                             
|\___   ___\\  \|\  \|\  ___ \                                                            
\|___ \  \_\ \  \\\  \ \   __/|                                                           
     \ \  \ \ \   __  \ \  \_|/__                                                         
      \ \  \ \ \  \ \  \ \  \_|\ \                                                        
       \ \__\ \ \__\ \__\ \_______\                                                       
        \|__|  \|__|\|__|\|_______|                                                       
                                                                                          
                                                                                          
                                                                                          
 ___  ___  ________  ________  ___  ___  ___  ___  ________                               
|\  \|\  \|\   __  \|\   ____\|\  \|\  \|\  \|\  \|\   __  \                              
\ \  \\\  \ \  \|\  \ \  \___|\ \  \\\  \ \  \\\  \ \  \|\  \                             
 \ \   __  \ \   __  \ \_____  \ \   __  \ \  \\\  \ \   ____\                            
  \ \  \ \  \ \  \ \  \|____|\  \ \  \ \  \ \  \\\  \ \  \___|                            
   \ \__\ \__\ \__\ \__\____\_\  \ \__\ \__\ \_______\ \__\                               
    \|__|\|__|\|__|\|__|\_________\|__|\|__|\|_______|\|__|                               
                       \|_________|                                                       
                                                                                          
                                                                                          
 ________  ________  ________  _________  ________  ___  ________  ________  _______      
|\   ____\|\   __  \|\   __  \|\___   ___\\   __  \|\  \|\   ___ \|\   ____\|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \|___ \  \_\ \  \|\  \ \  \ \  \_|\ \ \  \___|\ \   __/|    
 \ \  \    \ \   __  \ \   _  _\   \ \  \ \ \   _  _\ \  \ \  \ \\ \ \  \  __\ \  \_|/__  
  \ \  \____\ \  \ \  \ \  \\  \|   \ \  \ \ \  \\  \\ \  \ \  \_\\ \ \  \|\  \ \  \_|\ \ 
   \ \_______\ \__\ \__\ \__\\ _\    \ \__\ \ \__\\ _\\ \__\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|__|\|__|    \|__|  \|__|\|__|\|__|\|_______|\|_______|\|_______|
                                                                                          

BY

     _______.  ______    _______ .___________.  ______        _______. __    __   __                   
    /       | /  __  \  |   ____||           | /  __  \      /       ||  |  |  | |  |                  
   |   (----`|  |  |  | |  |__   `---|  |----`|  |  |  |    |   (----`|  |__|  | |  |                  
    \   \    |  |  |  | |   __|      |  |     |  |  |  |     \   \    |   __   | |  |                  
.----)   |   |  `--'  | |  |         |  |     |  `--'  | .----)   |   |  |  |  | |  |                  
|_______/     \______/  |__|         |__|      \______/  |_______/    |__|  |__| |__|                  
                                                                                                       
  _______      ___      .___  ___.  _______ .______      .___  ___.   ______   .___________.  ______   
 /  _____|    /   \     |   \/   | |   ____||   _  \     |   \/   |  /  __  \  |           | /  __  \  
|  |  __     /  ^  \    |  \  /  | |  |__   |  |_)  |    |  \  /  | |  |  |  | `---|  |----`|  |  |  | 
|  | |_ |   /  /_\  \   |  |\/|  | |   __|  |      /     |  |\/|  | |  |  |  |     |  |     |  |  |  | 
|  |__| |  /  _____  \  |  |  |  | |  |____ |  |\  \----.|  |  |  | |  `--'  |     |  |     |  `--'  | 
 \______| /__/     \__\ |__|  |__| |_______|| _| `._____||__|  |__|  \______/      |__|      \______/  



    __________________________
   |OFF  ON                   |
   | .----------------------. |
   | |  .----------------.  | |
   | |  |                |  | |
   | |))|                |  | |
   | |  |                |  | |
   | |  |                |  | |
   | |  |                |  | |
   | |  |                |  | |
   | |  |                |  | |
   | |  '----------------'  | |
   | |__GAME CHANGER________/ |
   |          ________        |
   |    .    (HashUp)         |
   |  _| |_   """"""""   .-.  |
   |-[_   _]-       .-. (   ) |
   |   |_|         (   ) '-'  |
   |    '           '-'   A   |
   |                 B        |
   |          ___   ___       |
   |         (___) (___)  ,., |
   |        select start ;:;: |
   |                    ,;:;' /
   |                   ,:;:'.'
   '-----------------------`


 _______ .______        ______ ___     ___                                                          
|   ____||   _  \      /      |__ \   / _ \                                                         
|  |__   |  |_)  |    |  ,----'  ) | | | | |                                                        
|   __|  |      /     |  |      / /  | | | |                                                        
|  |____ |  |\  \----.|  `----./ /_  | |_| |                                                        
|_______|| _| `._____| \______|____|  \___/                                                         
                                                                                                    
     _______.  ______    _______ .___________.____    __    ____  ___      .______       _______    
    /       | /  __  \  |   ____||           |\   \  /  \  /   / /   \     |   _  \     |   ____|   
   |   (----`|  |  |  | |  |__   `---|  |----` \   \/    \/   / /  ^  \    |  |_)  |    |  |__      
    \   \    |  |  |  | |   __|      |  |       \            / /  /_\  \   |      /     |   __|     
.----)   |   |  `--'  | |  |         |  |        \    /\    / /  _____  \  |  |\  \----.|  |____    
|_______/     \______/  |__|         |__|         \__/  \__/ /__/     \__\ | _| `._____||_______|   
                                                                                                    
 __       __    ______  _______ .__   __.      _______. _______                                     
|  |     |  |  /      ||   ____||  \ |  |     /       ||   ____|                                    
|  |     |  | |  ,----'|  |__   |   \|  |    |   (----`|  |__                                       
|  |     |  | |  |     |   __|  |  . `  |     \   \    |   __|                                      
|  `----.|  | |  `----.|  |____ |  |\   | .----)   |   |  |____                                     
|_______||__|  \______||_______||__| \__| |_______/    |_______|  

END USER LICENSE AGREEMENT


The Software (“the Software”) is licensed, not sold. By installing, copying, or otherwise using the Software you agree to be bound by the terms of this End User License Agreement (“the Agreement”) and the terms set forth below

The Agreement is strictly related to the Software tokenized in the form of ERC-20 cartridge and is binding only in relation to that specific carrier and Software emitted by Licensor. To launch and use the Software, you need to hold at least 1,0 original ERC-20 cartridges related to the Software emitted by the Licensor. In other cases, you are not allowed to launch the Software and you are in breach of the Agreement.

By opening, installing, and/or using the Software and any other materials included with the Software, you hereby accept the terms of this Agreement with Software Licensor (“Licensor”). 

If you do not agree to the terms of this Agreement, you are not permitted to use the Software.

FOR ANY PURCHASE OF DIGITAL CONTENT, YOU AGREE THAT LICENSOR MAKES THE PRODUCT AVAILABLE TO YOU FOR DOWNLOAD AND USE IMMEDIATELY AFTER PURCHASE.  ONCE MADE AVAILABLE, AS FAR AS PERMITTED BY LAW, YOU WILL HAVE NO RIGHT TO CANCEL YOUR ORDER OR TO A "COOLING OFF PERIOD" AND YOU CANNOT OBTAIN A REFUND, UNLESS EXPLICITLY STATED OTHERWISE BY LICENSOR OR THE THIRD-PARTY RETAILER.



§1
License

Subject to this Agreement and its terms and conditions, Licensor hereby grants you the non-exclusive, transferable, limited right and license to use one copy of the Software for your personal non-commercial use for gameplay, unless otherwise specified in the Software documentation.

You are allowed to use the software to record videos or live stream yourself using it on platforms like YouTube or Twitch, even if your channel has monetization, as long as you present the software using its full name and you don't misrepresent its origin nor claim that you are the author.

Transfer of the license described in point 1 can be made only with simultaneous transfer of the ERC-20 cartridge (original copy of the Software), in accordance with the conditions specified by the Licensor in the token generation event on GameContract.io platform. 

You agree that transfer of the license may incur automatic calculated costs like transactions fee, licensor commission, retailer platform commission and others.


§2
Ownership

The licensor is fully entitled to grant this license. No third-party rights are violated in connection with this agreement.

The Software is being licensed to you and you hereby acknowledge that no title or ownership in the Software is being transferred or assigned. Licensor retains all right, title and interest to the Software.

§3
License conditions

You agree not to and not to provide guidance or instruction to any other individual or entity on how to:

a. Commercially exploit the Software;
b. Distribute, lease, license, sell, rent or otherwise transfer or assign the Software, or any copies of the Software, without the express prior written consent of Licensor or as set forth in this Agreement;
c. Make a copy of the Software or any part thereof (other than as set forth herein);
d. Making a copy of this Software available on a network for use or download by multiple users;
e. Except as otherwise specifically provided by the Software or this Agreement, use or install the Software (or permit others to do same) on a network, for on-line use, or on more than one computer or gaming unit at the same time;
f. Use or copy the Software at a computer gaming center or any other location-based site; provided, that Licensor may offer you a separate site license Agreement to make the Software available for commercial use;.
g. Reverse engineer, decompile, disassemble, prepare derivative works based on or otherwise modify the Software, in whole or in part;
h. Remove or modify any proprietary notices, marks or labels contained on or within the Software.

§4
Warranty

The software is provided “as is”, and the Licensor makes no warranty of any kind, whether express or implied, regarding the product or its fitness for a particular purpose. The Licensor does not warrant that the product will meet licensee’s requirements, operate without interruption or be error free.

In no event will Licensor be liable for special, incidental or consequential damages resulting from possession, use or malfunction of the software, including, but not limited to, damages to property, loss of goodwill, computer failure or malfunction, and, to the extent permitted by law, damages for personal injuries, property damage, or lost profits or punitive damages from any causes of action arising out of or related to this agreement or the software, whether arising in tort (including negligence), contract, strict liability, or otherwise, whether or not licensor has been advised of the possibility of such damages. 

To the fullest extent of applicable law, licensor's liability for all damages shall not (except as required by applicable law) exceed the actual price paid by you for use of the software.

If you are a resident of an EU member state, notwithstanding anything to the contrary set out above, licensor is responsible for loss or damage you suffer that is a reasonably foreseeable result of licensor's breach of this agreement or its negligence, but it is not responsible for loss or damage that is not foreseeable.

§5
Taxes and Expenses

You shall be responsible and liable to Licensor and any and all of its affiliates, officers, directors, and employees for all taxes, duties, and levies of any kind imposed by any governmental entity with respect to the transactions contemplated under this Agreement, including interest and penalties thereon (exclusive of taxes on Licensor's net income), irrespective of whether included in any invoice sent to you at any time by Licensor. You shall provide copies of any and all exemption certificates to Licensor if you are entitled to any exemption. All expenses and costs incurred by you in connection with your activities hereunder, if any, are your sole responsibility. You are not entitled to reimbursement from Licensor for any expenses and will hold Licensor harmless therefrom.

§6
Termination

This Agreement is effective until terminated by you, by the Licensor, or automatically upon your failure to comply with its terms and conditions. Upon any termination, you must destroy or return the original copy of Software to the Licensor, as well as permanently destroy all copies of the Software, accompanying documentation, associated materials, and all of its component parts in your possession or control.

§7
Equitable remedies

You hereby agree that if the terms of this Agreement are not specifically enforced, Licensor will be irreparably damaged, and therefore you agree that Licensor shall be entitled, without bond, other security, proof of damages, to appropriate equitable remedies with respect any of this Agreement, in addition to any other available remedies.

§8
Governing law

This Agreement shall be governed by and construed in accordance with the laws of Licensor’s country of origin. Any dispute arising under or relating to this Agreement can be resolved by other entity designated by the licensor at its sole discretion. 

 */
contract HashupCartridge is IERC20, CartridgeMetadata {
	// Fee to creator on transfer
	uint256 public _creatorFee;

	// Amount of Cartridges gathered from fees
	uint256 private _feeCounter;

	// HashUp Store contract address
	address private _store;

	// Mapping address to Cartridge balance
	mapping(address => uint256) private _balances;

	// Mapping address to mapping of allowances
	mapping(address => mapping(address => uint256)) private _allowed;

	// Total amount of Cartridges
	uint256 private _totalSupply;

	// Whether {transferFrom} is available for users
	bool private _isOpen;

	constructor(
		string memory name_,
		string memory symbol_,
		string memory metadataUrl_,
		uint256 totalSupply_,
		uint256 creatorFee_,
		address store_
	) CartridgeMetadata(name_, symbol_, metadataUrl_, totalSupply_) {
		require(
			creatorFee_ < 100 * 10**feeDecimals(),
			"HashupCartridge: Incorrect fee"
		);
		_balances[msg.sender] = totalSupply_;
		_totalSupply = totalSupply_;
		_creatorFee = creatorFee_;
		_store = store_;
	}

	/**
	 * @dev See {IERC20-balanceOf}.
	 */
	function balanceOf(address owner)
		public
		view
		override
		returns (uint256 balance)
	{
		return _balances[owner];
	}

	/**
	 * @dev See {IERC20-totalSupply}.
	 */
	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev Returns percentage of amount that goes to the
	 * creator when transferring Cartridges
	 */
	function creatorFee() public view returns (uint256) {
		return _creatorFee;
	}

	/**
	 * @dev Returns sum of of Cartridges gathered
	 * by creator via transfer fees
	 */
	function feeCounter() public view returns (uint256) {
		return _feeCounter;
	}

	/**
	 * @dev Amount of decimals in fee number, its 1 so
	 * for example 5 is 0.5%  and 50 is 5%
	 */
	function feeDecimals() public pure returns (uint8) {
		return 1;
	}

	/**
	 * @dev Address of HashUp store that cartridge will
	 * be listed on. We save it here so interaction with
	 * store (for example sending games to it) doesn't
	 * take any fees
	 */
	function store() public view returns (address) {
		return _store;
	}

	/**
	 * @dev Address of HashUp store that cartridge will
	 * be listed on. We save it here so interaction with
	 * store (for example sending games to it) doesn't
	 * take any fees
	 */
	function setStore(address newStore) public onlyOwner {
		_store = newStore;
	}

	/**
	 * @dev Stores whether transferFrom is blocked,
	 * it can be unlocked by admin to enable it for
	 * usage in other smart contracts for example DEX
	 */
	function isOpen() public view returns (bool) {
		return _isOpen;
	}

	/**
	 * @dev See {IERC20-allowance}.
	 */
	function allowance(address owner, address spender)
		public
		view
		override
		returns (uint256 remaining)
	{
		return _allowed[owner][spender];
	}

	/**
	 * @dev Sets `_isOpen` to true and enables transferFrom
	 *
	 * Requirements:
	 * - sender must be admin
	 */
	function switchSale() public {
		require(
			msg.sender == owner(),
			"HashupCartridge: only admin can enable transferFrom"
		);
		_isOpen = true;
	}

	/**
	 * @dev See {IERC20-approve}.
	 *
	 * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
	 * `transferFrom`. This is semantically equivalent to an infinite approval.
	 *
	 * Requirements:
	 * - `spender` cannot be the zero address.
	 */
	function approve(address spender, uint256 value)
		public
		override
		returns (bool success)
	{
		_approve(msg.sender, spender, value);
		return true;
	}

	/**
	 * @dev See {IERC20-approve}.
	 */
	function _approve(
		address owner,
		address spender,
		uint256 value
	) internal {
		require(
			owner != address(0),
			"HashupCartridge: approve from the zero address"
		);
		require(
			spender != address(0),
			"HashupCartridge: approve to the zero address"
		);
		_allowed[owner][spender] = value;
		emit Approval(owner, spender, value);
	}

	/**
	 * @dev Splits value between recipient and Cartridge creator
	 *
	 * NOTE: If sender is store or owner it doesn't count
	 * creator fee and gives everything to recipient
	 **/
	function calculateFee(uint256 value, address sender)
		public
		view
		returns (uint256 recipientPart, uint256 creatorPart)
	{
		if (sender == _store || sender == owner()) {
			return (value, 0);
		}
		uint256 fee = (value * _creatorFee) / 1000;
		uint256 remaining = value - fee;

		return (remaining, fee);
	}

	/**
	 * @dev It calls _transferFrom that calculates and sends fee to Cartridge creator
	 **/
	function transfer(address to, uint256 value)
		public
		virtual
		override
		returns (bool success)
	{
		_transferFrom(msg.sender, to, value);
		return true;
	}

	/**
	 * @dev It calls _transferFrom that calculates and sends fee to Cartridge creator
	 * @inheritdoc IERC20
	 */
	function transferFrom(
		address from,
		address to,
		uint256 value
	) public virtual override returns (bool success) {
		require(
			from != address(0),
			"HashupCartridge: transfer from the zero address"
		);

		if (!_isOpen) {
			require(
				from == owner() || from == _store,
				"HashupCartridge: transferFrom is closed"
			);
		}

		_spendAllowance(from, msg.sender, value);
		_transferFrom(from, to, value);

		return true;
	}

	/**
	 * @dev Internal transfer from to remove redundance on transfer
	 * and transferFrom
	 */
	function _transferFrom(
		address _from,
		address _to,
		uint256 _value
	) internal {
		require(
			_to != address(0),
			"HashupCartridge: transfer to the zero address"
		);

		require(
			_balances[_from] >= _value,
			"HashupCartridge: insufficient token balance"
		);

		(uint256 recipientPart, uint256 creatorPart) = calculateFee(
			_value,
			_from
		);

		_balances[_from] -= _value;
		_balances[_to] += recipientPart;

		_balances[owner()] += creatorPart;
		_feeCounter += creatorPart;

		emit Transfer(_from, _to, _value);
	}

	/**
	 * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
	 * Does not update the allowance amount in case of infinite allowance.
	 * Revert if not enough allowance is available.
	 */
	function _spendAllowance(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance != type(uint256).max) {
			require(
				currentAllowance >= amount,
				"HashupCartridge: insufficient allowance"
			);
			unchecked {
				_approve(owner, spender, currentAllowance - amount);
			}
		}
	}
}