/**
 *Submitted for verification at polygonscan.com on 2023-07-14
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

contract BalancePool is Governance {

    using SafeMath for uint256;

    uint256 public totalTokens;
    address public TokenAddress = address(0x0);
    uint256 public Pool_ID;
    ITOKEN _itoken = ITOKEN(TokenAddress);
    uint256 public nonce = 0;

    mapping (uint256 => uint256) public tokens;
    event stakingToken(uint256 _fromId, uint256 _toId, uint256 amount);
    event unstakeToken(uint256 _tokenId, uint256 amount);
    event updateToken(uint256 nonce, uint256[] _id, int256[] _amount);

    constructor(){}

    function setSource( address _tokensrc , uint256 tokenID ) public
    {
        require( Pool_ID == 0, "Pool_ID exists");
        require( TokenAddress == address(0x0), "TokenAddress exists");

        Pool_ID = tokenID;
        TokenAddress = _tokensrc;
        _itoken = ITOKEN(TokenAddress);
        require( _itoken._exists(Pool_ID) , "POOL_ID not exists");
        require( msg.sender == _itoken.ownerOf(tokenID), "Owner invalid");
        require( _itoken.tokens(Pool_ID) == 0, "POOL_ID must empty");
    }

    function staking(uint256 from_Id, uint256 to_Id, uint256 amount) public
    {
        require( msg.sender == TokenAddress, "tokenId does not exist");
        require( from_Id != Pool_ID, "from_Id invalid");
        require( to_Id == Pool_ID, "to_Id invalid");

        tokens[from_Id] = tokens[from_Id].add(amount);
        totalTokens = totalTokens.add(amount);
     
        emit stakingToken(from_Id, to_Id, amount);
    }

    function unStake(uint256 tokenId, uint256 amount) public 
    {
        require( msg.sender == _itoken.ownerOf(tokenId), "Owner invalid");
        require( tokenId != Pool_ID, "tokenId invalid");
        require( tokens[tokenId] >= amount, "unstake too big");
        require( totalTokens >= amount, "totalTokens error");

        tokens[tokenId] = tokens[tokenId].sub(amount);
        totalTokens = totalTokens.sub(amount);
        _itoken.transferFrom( Pool_ID, tokenId , amount);

        emit unstakeToken(tokenId, amount);
    }

    /**
     * @dev Function to update by POOL_ID owner.
     */
    function update(uint256[] memory _id, int256[] memory _amount) external 
    {
        require( msg.sender == _itoken.ownerOf(Pool_ID), "Owner invalid");
    
        int256 chktotal = 0;
        for(uint i = 0; i < _id.length; i++)
        {
            chktotal = chktotal + _amount[i];
        }
        require( chktotal == 0, "total must balance");
       
        for(uint j = 0; j < _id.length; j++)
        {
            require( _id[j] != Pool_ID, "id invalid");
            if( _amount[j]< 0)
            {
                uint256 _tmp = (uint256)(0-_amount[j]);
                require( tokens[_id[j]] >= _tmp, "single error");
                tokens[_id[j]] = tokens[_id[j]] - _tmp;
            }
            else 
                tokens[_id[j]] = tokens[_id[j]] + (uint256)(_amount[j]);    
        }
        nonce += 1;
        emit updateToken( nonce, _id, _amount );
    }

}