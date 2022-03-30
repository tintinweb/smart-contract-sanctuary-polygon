/**
 *Submitted for verification at polygonscan.com on 2022-03-29
*/

/** 
 *  SourceUnit: e:\codegeek\Solidity\ERC20Distributor-usingMerkleProof\contracts\ERC20.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
}




/** 
 *  SourceUnit: e:\codegeek\Solidity\ERC20Distributor-usingMerkleProof\contracts\ERC20.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


/** 
 *  SourceUnit: e:\codegeek\Solidity\ERC20Distributor-usingMerkleProof\contracts\ERC20.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.4;
////import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol"; // this ////imported link contains ERC20Token and IRC20Token

contract ERC20Token is IERC20Metadata {
    // creating ERC20Token using the Token Standard
    // Token = T, TDECIMAL, TNAME, TSYMBOl
 
    // VARIABLES
    string private _tokenName;
    string private _tokenSymbol;
    uint8 private _tokenDecimal;
    uint256 private _totalSupply;

    mapping (address => uint256) balances;
    mapping(address => mapping(address => uint256)) _allowance;

    // FUNCTIONS

    constructor(
        string memory tokenName_,
        string memory tokenSymbol_,
        uint8 tokenDecimal_,
        uint256 totalSupply_
    )
    {
        _tokenName = tokenName_;
        _tokenSymbol = tokenSymbol_;
        _tokenDecimal = tokenDecimal_;
        _totalSupply = totalSupply_;
        balances[msg.sender] = _totalSupply;
    }

    

    function name() external override view returns (string memory){
        return _tokenName;
    }

    function symbol() external override view returns (string memory){
        return _tokenSymbol;
    }

    function decimals() external override view returns (uint8){
        return _tokenDecimal;
    }

    function totalSupply() external override view returns (uint256){
        return _totalSupply;
    }

    // Account Balance

    function balanceOf(address account) external override view returns (uint256){
        return balances[account]; 
    }

    // Transfer
    function _transfer(address _from, address _to, uint256 _amount) internal returns(bool){
        require(_amount <= balances[_from], " Insufficient Balance");
        balances[_from] -= _amount;
        balances[_to] += _amount;
        //return true;

        emit Transfer(_from, _to, _amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool){
        _transfer(msg.sender, to, amount);

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // Allowance
    function allowance(address owner, address spender) public view override returns (uint256){
        return _allowance[owner][spender];
    }

    

    // Approve
    function approve(address spender, uint256 amount) external override returns (bool){
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender, amount);
        return true;
    }

    // Transfer from
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool)
    {
       uint256 _allowedAmount = allowance(from, msg.sender);
       require(amount <= _allowedAmount, "You do not have suffcient amount approved");
       _allowance[from][msg.sender] -= amount;
       _transfer(from, to, amount);
       emit Transfer(msg.sender, to, amount);
       return true;
    }
}

// TEST ACCT1 0x793304f421b09D8fDa4225d7AAE33483fDA5406F

// TEST ACCT2 0x7cC71EE395b3ec41F04dCD9b13a079dA859A88a1

// OWNER ACCT 0xC635dC7e540d384876aC4D6178D9971241b8383B

// CONTRACT ADDRESS 0xe2326ce3317ba999b90f3ee2bff526f928a2e672