/**
 *Submitted for verification at polygonscan.com on 2022-08-14
*/

// File: @openzeppelin/[email protected]/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: contracts/TTZToken.sol

/* -------------------------------------------------
 *  Dirk Wagner's TutorZ TTZ ERC20 token
 * ------------------------------------------------ */ 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract TTZToken {
    /* -------------------------------------------------
     *  
     *  Implementation of the ERC20 standard (part 1)
     * 
     * ------------------------------------------------ */    
    // the TTZ token name and ticker symbol
    string private   _name = "TutorZ Token";
    string private _symbol = "TTZ";

    // total supply of TTZ tokens is 1 Million allocated to the creator of the contract
    // internally represented in 1M * 10^18 or 1000000.000 000 000 000 000 000
    uint256 private constant TOTAL_SUPPLY = 1 * (10 ** 6) * (10 ** 18);
    uint256 private _totalSupply = 0;

    address private _owner;

    // keep track of the balances of each token owner
    mapping(address => uint256) private _balances;

    // keep track of the token spending allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _owner = msg.sender;
        _mint(_owner, TOTAL_SUPPLY);
    } 

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract.
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }
   
    function balanceOf(address who) external view returns (uint256) {
        return _balances[who];
    }

   /**
    * Transfers `amount` of tokens to address `to`, and fires the Transfer event. 
    * The function throws if the message caller's account balance does not have enough tokens to spend. 
    */
    function transfer(address to, uint256 amount) public returns (bool) {
        
        _transfer(msg.sender, to, amount);

        return true;
    }

   /** 
    * Allows the `spender` to withdraw from your account, multiple times, up to the `amount`.
    * If this function is called again it overwrites the current allowance with amount.
    */
    function approve(address spender, uint256 amount) external returns (bool) {
        
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

   /** 
    * Returns the amount which `spender` is still allowed to withdraw from `owner`.
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }    

   /**
    * Transfers `amount` of tokens from address `from` to address `to`. Fire the Transfer event.
    * 
    * The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens 
    * on your behalf. This can be used for example to allow a contract to transfer tokens on your behalf
    * and/or to charge fees in sub-currencies. 
    *
    * The function throws unless the `from` account has deliberately authorized the sender of the message 
    * via the approve() method.
    *
    * Transfers of 0 values are treated as normal transfers and fire the Transfer event.
    */
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {

        // allowance must be big enough
        require(amount <= _allowances[from][msg.sender]);

        _transfer(from, to, amount);

        // update the allowances
        _allowances[from][msg.sender] -= amount;

        return true;
    }
       
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );    

    /**
     * Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TTZToken: mint to the zero address");

        _newReceipient(account);

        _totalSupply += amount;
      
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }

        emit Transfer(address(0), account, amount);
    }  


   /**
    * Transfers `amount` of tokens from creditor address `from` to receipient address `to`, 
    * and fires the Transfer event. 
    * The function throws if the message caller's account balance does not have enough tokens to spend. 
    */
    function _transfer(address from, address to, uint256 amount) internal {

        // creditor `from` must have enough tokens
        require(amount <= _balances[from], _concat("TTZToken::_transfer() - account owner has insufficient TTZ tokens: ", Strings.toString(_balances[from]) ) );

        // it makes no sense not having a transfer to address
        require(to != address(0), "TTZToken: transfer to a zero address");

        // record first-time receipients for use in the getBalances() method
        _newReceipient(to);

        // transfer the balance
        _balances[from] -= amount;
        _balances[to]   += amount;

        // emit transfer event
        emit Transfer(from, to, amount);
    }     

    /* -------------------------------------------------
     *  
     *  faucet (part 2)
     * 
     * ------------------------------------------------ */
    // amount of TTZ tokens than can be claimed in one faucet  operation: 10 TTZ token
    uint256 _drawAmount = 10 * (10 ** 18); 

    // unique addresses of the receipients receiving funds from the faucet
    address[] private _receipients;

    // keep a 1 day lock on each address drawing tokens from the faucet
    mapping(address => uint) private _lockTime;

    // event to be transmitted upon drawing tokens from the faucet
    event Draw(address indexed receipient, uint256 indexed amount); 

    modifier ownerOnly() {
        require(msg.sender == _owner, "Only the contact owner can call this function.");
        _;
    }

   /**
    * Allows users to draw 10 TTZ tokens from the faucet.
    * Only the contract owner `_owner` is allowed to call this function 
    * as this functionality will be implemented by the web-front then. 
    * Users can drow only once within 24 hours.
    */
    function draw(address receipient) external ownerOnly {        
        // these pre-conditions must hold in order for the draw to be satisfied
        
        require(block.timestamp > _lockTime[msg.sender], "You're claiming too fast. Come again tomorrow");
        require(_balances[_owner] > _drawAmount, _concat("Insufficient funds in the faucet. Minimum required=", Strings.toString(_drawAmount) ) );

        // transfer 10 TTZ tokens from Dirk's account to receipient
        _transfer(_owner, receipient, _drawAmount);
        
        // receipient is allowed to draw once every 24 hours
        _lockTime[msg.sender] = block.timestamp + 1 days;

        emit Draw(receipient, _drawAmount);        
    }

   /**
    * Returns the addresses holding TTZ tokens and their balances
    * Since there is no way to return a mapping in solidity, the work around is it return 2 arrays
    */
    function getBalances() external view ownerOnly returns (address[] memory, uint[] memory) {
        address[] memory mReceipients = new address[](_receipients.length);
           uint[] memory mBalances    = new    uint[](_receipients.length);

        for (uint i=0; i<_receipients.length; i++) {
            mReceipients[i] = _receipients[i];
            mBalances[i]    = _balances[_receipients[i]];
        }
        return (mReceipients, mBalances);
    }  

   /**
    * Record first-time receipients for use in the getBalances() method
    */ 
    function _newReceipient(address receipient) internal {
        if(_balances[receipient] == 0) {
            _receipients.push(receipient);
        }
    } 

    function _concat(string memory a, string memory b) internal pure returns(string memory){
        return (string(abi.encodePacked(a, b)));
    }                 
}