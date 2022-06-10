/**
 *Submitted for verification at polygonscan.com on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*
                                   .╔╦H╙╙╩N╦,.                                  
  ╗╦µ,.                    .,╔╦╦H╨"`        `"╙ª%╦╦µ,.                    .,╔╗r 
  ╬  ``""╙╚ºªª%%%%%%ªªª╨╙""`         .╔╗▄╗µ.        ``""╙╨ªªº%%%%%%ªªª╨╙╙"`` ╠H 
  ╫⌐                         ,,╓╗▄╫▓▓▓▓▓▓▓▓▓▓▓▒▄╗µ,.                         ╟H 
  ╫H   ║▓▒▄▄▄╦╗╗╗╗╗╗╦╗▄▄▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▄▄▄╦╗╗╗╗╗╗╗╗▄▄▄▓⌐   ╟⌐ 
  jH   ╟▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀╫▄▀▀▀▀▀▀▀▀╫▀▓▓▓▓▓▓▓⌐   ╟` 
  jN   j▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓K█▌▀▀▀▀▀▀▀╫Ñ▓▓▓▓▓▓▓▓`   ╫  
  :Ñ   j▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀▀▒▒▄▓╫▄░╠╣╦░╫╫Ü╣▓▓▓▓▓▓▌    ╫  
   Ñ   .▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀╫▄▄╫▒╣▒▓▓Φ╣▄▄▄▄▄▄▓╫▀▀╫╫╫╫╫▓██▌╠╫▌╫╠▓▓▓▓▓▓▓▌    ╫  
   ╬    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▄▓▀▀╫▓╫╫▓╫╫╫▀╫▓╣╫▒╫▄╣╫╫╫╫╫╫╫╫╣╫██▓▓Ñ╫▓▓▓▓▓▓▓▓▌    ╫  
   ╬    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌╣▓▌╫▓▓╫╫▀╫╫╫╫╣╫╫▒▀╫╫▒╫╫▌╫╫╫╫╫▒╫╫╣▒╫▓╫▒╬▓▓▓▓▓▓▓▓▓▌    ╫  
   ╟    ╣▓▓▓▀▓▓▓▓▓▓▓▓▀╫▓▌▓███╫▓╫╫╣╫╫▓╫╫▄╣▄▓╫▓╫╫▒╫╫▀╫╫╫╬╫╫╫╫▌╫▓▓▓▓▓▓▓▓▓▓▓▌   :Ñ  
   ╟⌐   ╫▓▀▄█N╣▓▓▓▓▀▄▓▓▓█▀░▓▓▒▓▌▀╫▀▄▒▀╬╫╬╫▓▒▀╫▓▒╫╫╬╫╫╫╫▌╫╣▓▒╣▓▓▓▓▓▓▓▓▓▓▓▌   jÑ  
   ╟⌂   ╫▓░██▄▀▀╣▄╫▓▒▓▀▒╫╠▓▀▀▌╫╫╫▓██████▓▓▄▒╫█▀╫╫╫╫╫▄▓█╫▄▓█╫▓▓▓▓▓▓▓▓▓▓▓▓Ñ   jH  
   ]H   ║▓▓╬▀██▓▓▓▀▀╫╦▄▄▀▓▒╣▀╫██▓▀Φ╟█▒▓▒▒█▓▀▀▀█▓▌╫╫╫▓█▓█▀▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓M   jH  
   jH   ║▓▓▓▓▓▓▓▓▓▓▌╦▓╠▌╫▓╫▀▀▀▒╫▓Ñ▓▌╫Ñ╫▓▀╫▓▓▓▓Ñ▓▌╫╫▓▌╚█╫╫╣M▓▓▓▓▓▓▓▓▓▓▓▓▓M   ╟H  
   jÑ   ╟▓▓▓▓▓▓▓▓▓▓M▓Ü░▓╣╣▓▓▓▓▓▓▓▓▄▀▓░▓▄╣▓▓▓▓▓▓H▓╫Ü╫▒╫║█Ñ╫Ñ╣▓▓▓▓▓▓▓▓▓▓▓▓░   ╟⌐  
   `Ñ   j▓▓▓▓▓▓▓▓▓▓M▓Ü╫▌╠▀▓▓▓▓▓▓▓▓▓▓╬▓▄╣╬╫╫▀▓▓▓▌╠▓░░▀ÑÑ╟▌░▓╬╫▀▓▓▓▓▓▓▓▓▓▓⌐   ╟⌐  
    ╫   `▀▀▀▀▀▀▀▀▀▀"▀▀▀▀▀╙▀▀▀▀▀▀▀▀▀▀▀╨▀▀▀▀▀╩╨▀▀▀╩╝▀▀▀▀▀┴╝▀▀▀▀╩╨▀▀▀▀▀▀▀▀▀    ╟   
    ╫                                                                       ╫   
    ╬         ╣▓▓▓Ñ      ▓▓▓▓M       ╣▓▓▓▓▄        ╟▓▓▓▓▓▓▓▓▓▓▓▄,           ╫   
    ╟⌐        ╣▓▓▓Ñ      ▓▓▓▓M      ╣▓▓▓▓▓▓▄       ╟▓▓▓▓▀▀▀▀▀▓▓▓▓▄         jÑ   
    ]N        ╣▓▓▓Ñ      ▓▓▓▓M     ╣▓▓▓▀╣▓▓▓▄      ╟▓▓▓▌     ╟▓▓▓▌         ╟⌐   
     ╬        ╣▓▓▓Ñ      ▓▓▓▓M    ╣▓▓▓▌  ▓▓▓▓▄     ╟▓▓▓▌╗╗╗╗▄▓▓▓▓M        jÑ    
     ╚N       ╣▓▓▓▌     :▓▓▓▓H   ╟▓▓▓▓▄▄▄╣▓▓▓▓N    ╟▓▓▓▓▓▓▓▓▓▓▌▀`         ╬`    
      ╟U      ╚▓▓▓▓▒╗µ╔╗▓▓▓▓▌   ╗▓▓▓▓▓▓▓▓▓▓▓▓▓▓╦   ╟▓▓▓▌  ╙▓▓▓▓▄         ╬H     
       ╟⌂      ╙▀▓▓▓▓▓▓▓▓▓▓M   ╟▓▓▓▌"      ╙▓▓▓▓U  ╟▓▓▓▌    ╣▓▓▓▓φ      ╟H      
        ╟µ        `"╙╨╙""      """"`        `""""  `""""     """""`    ╬┘       
         ╙N     ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,     ,Ñ`        
           ╟µ    ╝▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌╨    éM          
            "Ñ≈    ╙▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀"    ╔M            
              `╬µ    "▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀`    ╗M              
                `╚╦,    "▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀`    ╓#╨                
                   "╚╦.    `╙▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀╨`    ,╦╨`                  
                      "╚╦,     `╨▀▓▓▓▓▓▓▓▓▓▓▓▓▓▀╨`     ╔@╜`                     
                         `╙¥╦.     `╙▀▀▓▓▓▀╩"      ,╦╩╨                         
                             `╙M╦w            .╔╦╩*`                            
                                  "╚%╦w. .╔╦M╙"                                 
                                       `"`                                      
*/

library SafeERC20 {
   
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(isContract(address(token)), "Call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(abi.encodeWithSelector(token.transfer.selector, to, value));
        bytes memory returnedData = verifyCallResult(success, returndata, "Call reverted");
        if (returnedData.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "ERC20 operation did not succeed");
        }
    }

    function safeTransferFrom(IERC20 token ,address from, address to, uint256 value) internal {
        require(isContract(address(token)), "Call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        bytes memory returnedData = verifyCallResult(success, returndata, "Call to non-contract");
        if (returnedData.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

abstract contract Admin is Ownable {
    /** This is a flag that validates an address as admin*/
    uint128 ADMIN = 1;

    /** Admin population
     *
     * NOTE: This is initializated in one because when the owner deploy this contract,
     * he becames an admin.
     *
    */
    uint128 public adminPopulation = 1;

    /** Admin added*/
    event AddedAdmin(address indexed _addedBy, address indexed _addedAdmin);
    
    /** Admin removed*/
    event RemovedAdmin(address indexed _removedBy, address indexed _removedAdmin);

    /** Change of state*/
    event ChangedState(uint8 _previousState, uint8 _newState);

    /** Record of admins*/
    mapping(address => uint256) public isAdmin;

    /** Only a valid admin */
    modifier onlyAdmin {
        require(isAdmin[msg.sender] == ADMIN, "You are not admin. You can't do that.");
        _;
    }

    constructor() {
        isAdmin[msg.sender] = ADMIN;
    }

    function addAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0) && isAdmin[_newAdmin] != ADMIN);
        require(msg.sender != _newAdmin);
        
        isAdmin[_newAdmin] = ADMIN;
        adminPopulation++;

        emit AddedAdmin(msg.sender, _newAdmin);
    }

    function removeAdmin(address _oldAdmin) public onlyAdmin {
        require((isAdmin[_oldAdmin] == ADMIN) && (_oldAdmin != owner()), "The address has to be an admin");

        isAdmin[_oldAdmin] = 2;
        adminPopulation--;

        emit RemovedAdmin(msg.sender, _oldAdmin);
    }

}

interface AggregatorV3Interface {

  function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
   );

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ReEntrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

}

contract ERC20 is IERC20, IERC20Metadata, Admin, ReEntrancyGuard {

    enum State {
        ACTIVE,
        INACTIVE
    }

    uint8 public state = uint8(State.ACTIVE);
    
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    modifier activeContract {
        require(state == uint8(State.ACTIVE), "The contract need to be active!");
        _;
    }

    modifier inactiveContract {
        require(state == uint8(State.INACTIVE), "The contract need to be inactive!");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual activeContract override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(address spender, uint256 amount) public virtual activeContract override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual activeContract override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public activeContract virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public activeContract virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

}

contract FanToken is ERC20 {
    using SafeERC20 for IERC20;                         /* To accept USDT           */
    address public USDT;                                /* USDT Token address       */

    AggregatorV3Interface public maticFeed;             /* Matic to USD oracle      */
    int256  public lastMaticPrice;                      /* Last price known         */
    uint256 public lastMaticUpdate;                     /* Last timestamp known     */

    uint256 public unit;                                /* Unit for the token price */
    address payable recipient;                          /* Where funds will go      */
    uint256 public tokenPrice;                          /* Token price in dollars   */

    /* Voting logic for deactivating the contract:                                  *
     *      1) Only admins can vote.                                                *
     *      2) Can vote only once.                                                  *
     *      3) We need full quorum*.                                                *
     *      4) We can DEACTIVATE or ACTIVATE the contract.                          *

     *: I know that the possibility of loosing an address exists, then in order to  *
     have full quorum, another admin has to remove the previus admin with the       *
     function removeAdmin().                                                        */

    uint256 public votes;                               /* Amount of votes          */
    mapping(address => uint256) public hasVoted;        /* If an admin has voted    */

    uint128 constant private VOTE_FOR_ACTIVE   = 1;     /* Vote for SC activation   */
    uint128 constant private VOTE_FOR_INACTIVE = 2;     /* Vote for SC deactivation */

    constructor(uint256 _initialSupply,                 /* Initial supply           */
                uint256 _tokenPrice,                    /* Dollars with 8 decimal   */
                uint256 _newUnit,                       /* Unit for the token price */
                address payable _recipient,             /* Where funds will go      */
                address _oracle,                        /* MATIC/USD oracle         */
                address _USDT)                          /* USDT Token address       */
                ERC20('UARToken', 'UAR') {              /* Building the ERC20 SC    */
        _mint(address(this), _initialSupply);           /* Minting to the SC        */
        recipient   = _recipient;                       /* Declare the recipient    */
        tokenPrice  = _tokenPrice;                      /* First token price        */ 
        unit        = _newUnit;                         /* First token unit         */
        maticFeed   = AggregatorV3Interface(_oracle);   /* Instance of Oracle       */
        USDT        = _USDT;                            /* USDT Polygon's address   */   
        _updateMaticPrice();                            /* Update feed and timestamp*/
    }

    
    event newMATICPurchase(address indexed buyer,       /* MATIC purchase           */
                      uint256 amount /*Of tokens*/,
                      uint256 price);

    event newUSDTPurchase(address indexed buyer,        /* USDT purchase            */
                      uint256 amount /*Of tokens*/,
                      uint256 price);

    /**                                                                             *
     * @dev Mint tokens to the owner / admin.                                       *
     *                                                                              *
     * @param _amount The amount of tokens to mint.                                 *
     * @dev This is onlyOwner because we don't have in mind minting tokens          *
     */
    function mintTokens(uint256 _amount) public
                                         onlyOwner activeContract {
        require(_amount > 0, "Minimum 1 token");    /* At least one token           */
        _mint(msg.sender, _amount);                 /* Mint tokens                  */
        _updateMaticPrice();                        /* Update MATIC price           */
    }

    /**                                                                             *
     * @dev Buy tokens with MATIC.                                                  *
     *                                                                              *
     * @param _amountOfTokens The amount of tokens to buy                           *
     * @dev It's recommended to call getWeiNeeded before calling this function      *
     */
    function buyTokensWithMATIC(uint256 _amountOfTokens) public payable
                                                nonReentrant activeContract {
        require((_amountOfTokens > 0) && (msg.value > 0), "Invalid amounts");
        
        _updateMaticPrice();
        
        uint256 priceInWei = ((tokenPrice * unit) * _amountOfTokens) * 1e9;
        uint256 result     = (priceInWei / uint(lastMaticPrice)) * 1e9;
        require((msg.value >= result), "The MATIC price just change. Check again.");
        
        // Proceding with the call means that the user send a sufficient amount
        // Send value to recipient
        (bool success, ) = address(recipient).call{value: msg.value}("");
        require(success, "Address: unable to send value, recipient may have reverted");

        // Send the tokens and create a lock
        this.transfer(msg.sender, _amountOfTokens);
        
        emit newMATICPurchase(msg.sender, _amountOfTokens, tokenPrice * _amountOfTokens);
    }

    /**                                                                             *
     * @dev Buy tokens with USDT.                                                   *
     *                                                                              *
     * @param _amountOfTokens The amount of tokens to buy                           *
     * @dev It's required to increase allowance to the address recipient in order to*
     *      pay with USDT.                                                          *
     */
    function buyTokensWithUSDT(uint256 _amountOfTokens) public
                                                nonReentrant activeContract {
        require(_amountOfTokens > 0, "Invalid amount");

        _updateMaticPrice();
        uint256 priceInDollars = ((tokenPrice * unit) * _amountOfTokens) * 1e6;

        require(IERC20(USDT).balanceOf(msg.sender) >= priceInDollars, 
                                                "Insufficient USDT amount");

        require(IERC20(USDT).allowance(msg.sender, address(this)) >= priceInDollars,
                                                "Contract has not enough allowance");

        // Send value to recipient
        IERC20(USDT).safeTransferFrom(msg.sender, recipient, priceInDollars);

        // Send the tokens and create a lock
        this.transfer(msg.sender, _amountOfTokens);
        
        emit newUSDTPurchase(msg.sender, _amountOfTokens, tokenPrice * _amountOfTokens);
    }

    /**                                                                             *
     * @dev Set the token price variable                                            *
     *                                                                              *
     * @param _newPrice New token price in dollars with 0 units                     *
     */
    function setTokenPrice(uint256 _newPrice) public
                                              onlyAdmin activeContract {
        _updateMaticPrice();
        tokenPrice = _newPrice;
    }

    /**
     * @dev Set the unit
     * @param _newUnit New unit
     * @dev Used to balance the token price
     */
    function setUnit(uint _newUnit) public onlyAdmin activeContract {
        _updateMaticPrice();
        unit = _newUnit;
    }

    /**                                                                             *
     * @dev Vote for smart contract inactivation                                    *
     * @dev All admins has to vote                                                  *
     */
    function voteForInactivation() public
                                   onlyAdmin activeContract {
        require(hasVoted[msg.sender] != VOTE_FOR_INACTIVE, "You can vote only once!");
        hasVoted[msg.sender] = VOTE_FOR_INACTIVE;
        votes++;
        
        if (votes >= adminPopulation) {
            state = uint8(State.INACTIVE);
            votes = 0;
        }

        emit ChangedState(uint8(State.ACTIVE), uint8(State.INACTIVE));
    }

    /**                                                                             *
     * @dev Vote for smart contract activation plus update MATIC price              *
     * @dev All admins has to vote                                                  *
     */
    function voteForActivation() public
                                 onlyAdmin inactiveContract {
        require(hasVoted[msg.sender] != VOTE_FOR_ACTIVE, "You can vote only once!");
        hasVoted[msg.sender] = VOTE_FOR_ACTIVE;
        votes++;
        
        if (votes >= adminPopulation) {
            state = uint8(State.ACTIVE);
            votes = 0;
        }

        emit ChangedState(uint8(State.INACTIVE), uint8(State.ACTIVE));
        _updateMaticPrice();
    }

    /**                                                                             *
     * @dev Update the MATIC price plus the timestamp                               *
     * @dev NOTE If the price is different, update it                               *
     */
    function _updateMaticPrice() public {
        (, int _newPrice, uint _newPriceTime, ,) = maticFeed.latestRoundData();
        if (_newPrice != lastMaticPrice) {
            lastMaticPrice  = _newPrice;
            lastMaticUpdate = _newPriceTime;
        }
    }

    /**                                                                             *
     * @dev Returns the MATIC price plus the timestamp from the Oracle              *
     */
    function getOracleMaticPrice() public view returns(int256  answer,
                                                      uint256 timestamp) {
        (, answer, timestamp, ,) = maticFeed.latestRoundData();
    }

    /**                                                                             *
     * @dev Returns the MATIC needed for buying _amountOfTokens.                    *
     * @dev Note: This is the same math that the buy tokens function does           *
     */
    function getWeiNeeded(uint256 _amountOfTokens) public view returns(uint256) {
        return ((((tokenPrice * unit) * _amountOfTokens) * 1e9) / uint(lastMaticPrice) * 1e9);
    }
}