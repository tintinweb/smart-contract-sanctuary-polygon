/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Governance {

    address _governance;

    constructor() {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }
}

interface IBODY
{
    function Metadata_Update(uint256 tokenId) external;
    function _exists(uint256 tokenId) external view returns (bool);
    function withdrawfee() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ITOKEN
{
    function depositCross(uint256 tokenId, uint256 amount, bytes memory txhash) external;
    function withdrawCross(uint256 tokenId, uint256 amount) external;
    function transfer(uint256 from_id, uint256 to_id, uint256 value) external returns (bool);
    function tokens(uint256 tokenId) external view returns (uint256);
    function approve(uint256 tokenId, address spender, uint256 amount) external returns (bool);
    function allowance(uint256 tokenId, address spender) external view returns (uint256);
    function transferFrom(uint256 from_id, uint256 to_id, uint256 value) external returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function _exists(uint256 tokenId) external view returns (bool);
}

interface IPOOL
{
    function setSource( address _tokensrc , uint256 tokenID ) external;
    function staking(uint256 from_Id, uint256 to_Id, uint256 amount) external;
}

contract IdToken is Governance 
{
    using SafeMath for uint256;

    struct Erc20Token {
        string name;
        string symbol;
        uint256 decimals;
        uint256 totalsupply;
        bool flag;
    }
    
    Erc20Token public thistoken;
    address public bodyAddress = address(0x0);
    IBODY _body = IBODY(bodyAddress);
    uint256 public totalTokens;
    uint256 public feeamount = 0;

    mapping (uint256 => uint256) public tokens;
    mapping (uint256 => mapping (address => uint256)) _allowances;

    event depositToken(uint256 _tokenId, uint256 amount, bytes txhash);
    event withdrawToken(uint256 _tokenId, uint256 amount, uint256 fee);
    event iTransfer(uint256 _fromId,uint256 _toId,uint256 amount);
    event iApproval(uint256 _fromId,address _spender,uint256 amount);

    function enable(string memory _name, string memory _symbol, uint256 _decimals) public
    { 
        require( !thistoken.flag, "Token enabled");
        thistoken.name = _name;
        thistoken.symbol = _symbol;
        thistoken.decimals = _decimals;
        thistoken.flag = true;

        bodyAddress = msg.sender;
        _body = IBODY(bodyAddress);
    }

    function depositCross(uint256 tokenId, uint256 amount, bytes memory txhash) public
    {
        require( msg.sender == bodyAddress, "tokenId does not exist");
        require(_body._exists(tokenId), "tokenId does not exist");
        tokens[tokenId] = tokens[tokenId].add(amount);
        totalTokens = totalTokens.add(amount);
        Metadata_Update(tokenId);
        emit depositToken(tokenId, amount, txhash);
    }

    function withdrawCross(uint256 tokenId, uint256 amount) public {
        require( msg.sender == bodyAddress, "tokenId does not exist");
        require( _body._exists(tokenId), "tokenId does not exist");
        uint256 nowfee =  withdrawfee();
        require( amount >= nowfee, "amount lower than fee");

        tokens[tokenId] = tokens[tokenId].sub(nowfee);
        tokens[tokenId] = tokens[tokenId].sub(amount);
        totalTokens = totalTokens.sub(amount);
        feeamount = feeamount.add(nowfee);
        Metadata_Update(tokenId);
        emit withdrawToken(tokenId, amount, nowfee);
    }

    function transfer(uint256 from_id, uint256 to_id, uint256 value) external returns (bool)  
    {
        require( msg.sender == bodyAddress, "operator invalid");
        require(_body._exists(from_id), "tokenId does not exist");
        return _transfer(from_id,to_id,value);
    }

    function _transfer(uint256 from_id, uint256 to_id, uint256 value) internal returns (bool)
    {
        tokens[from_id] = tokens[from_id].sub(value);
        tokens[to_id] = tokens[to_id].add(value);
        emit iTransfer(from_id, to_id, value);
        Metadata_Update(from_id);
        Metadata_Update(to_id);
        return true;
    }

    function withdrawfee() public view returns ( uint256 )
    {
        return _body.withdrawfee();
    }

    function approve(uint256 tokenId, address spender, uint256 amount) external returns (bool) 
    {
        require(_body._exists(tokenId), "tokenId does not exist");
        address owner = _body.ownerOf(tokenId);
        require( msg.sender == owner, "approve caller is not owner");

        _allowances[tokenId][spender] = amount;
        emit iApproval(tokenId, spender, amount);
        return true;
    }

    function allowance(uint256 tokenId, address spender) public view returns (uint256) 
    {
        return _allowances[tokenId][spender];
    }

    function transferFrom(uint256 from_id, uint256 to_id, uint256 value) external returns (bool) 
    {
        require(_body._exists(from_id), "tokenId does not exist");
        address owner = _body.ownerOf(from_id);
        require( tx.origin == owner, "tx caller is not owner");

        uint256 allow = _allowances[from_id][msg.sender];
        _allowances[from_id][msg.sender] = allow.sub(value);
        
        Metadata_Update(from_id);
        Metadata_Update(to_id);
        return _transfer(from_id, to_id, value);
    }

    function name() public view returns (string memory )
    {
        return thistoken.name;
    }

    function symbol() public view returns (string memory )
    {
        return thistoken.symbol;
    }

    function decimals() public view returns (uint256)
    {
        return thistoken.decimals;
    } 

    function totalSupply() public view returns (uint256)
    {
        return thistoken.totalsupply;
    }

    function isenable() public view returns (bool)
    {
        return thistoken.flag;
    }
    
    function ownerOf(uint256 tokenId) public view returns (address)
    {
        return _body.ownerOf(tokenId);
    }

    function setBodyAddress( address _bodyaddr ) external onlyGovernance
    {
        bodyAddress = _bodyaddr;
        _body = IBODY(bodyAddress);
    }

    function PoolContract( address newcontract, uint256 tokenId ) external onlyGovernance
    {
        IPOOL _pool = IPOOL(newcontract);
        _pool.setSource( address(this), tokenId );
    }

    function Staking( address newcontract, uint256 from_id, uint256 to_id, uint256 amount ) external
    {
        address owner = _body.ownerOf(from_id);
        require( msg.sender == owner, "caller is not owner");
        require( tokens[from_id] >= amount, "unstake too big");

        _transfer( from_id, to_id, amount);

        IPOOL _pool = IPOOL(newcontract);
        _pool.staking( from_id, to_id, amount);

        _allowances[to_id][newcontract] = type(uint256).max;
    }

    function _exists(uint256 tokenId) public view returns (bool)
    {
        return _body._exists(tokenId);
    }

    function Metadata_Update(uint256 tokenId) public {
        _body.Metadata_Update(tokenId);
    }

}