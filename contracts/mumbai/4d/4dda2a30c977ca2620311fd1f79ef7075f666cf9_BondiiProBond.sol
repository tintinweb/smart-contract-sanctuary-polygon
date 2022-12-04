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

    function decimals() view external returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ITreasury {
    function sendPayoutTokens(uint _amountPayoutToken) external;

    function sendStakingReward(address _staking_contract, uint _amount) external;

    function whitelistBondContract(address _new_bond) external;

    function dewhitelistBondContract(address _bondContract) external;

    function valueOfToken( address _principalTokenAddress, uint _amount ) external view returns ( uint value_ );

    function bondPayoutToken() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;


library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./FullMath.sol";


library Babylonian {

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

library BitMath {

    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}


library FixedPoint {

    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
    
    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= type(uint144).max) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, type(uint256).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & (type(uint256).max - d);
        d /= pow2;
        l /= pow2;
        l += h * ((type(uint256).max - pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "../interfaces/IERC20.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/FixedPoint.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITreasury.sol";
import "./Ownable.sol";



/// @author @developeruche
/// @author @casweeney
/// @author @olahfemi
/// @author @aagbotemi
/// @author @Adebara123
/// @notice this contract would be used to handle the bonding mechanism, it would be deplyed by the bondii pro factory
contract BondiiProBond is Ownable {
    /**
     * ===================================================
     * ----------------- LIBRARIES -----------------------
     * ===================================================
     */
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using FixedPoint for *;

    
    /* 
     * ===================================================
     * -------------------- EVENTS -----------------------      
     * ===================================================
     */
    event BondCreated( uint deposit, uint payout, uint expires );
    event BondRedeemed( address recipient, uint payout, uint remaining );
    event BondPriceChanged( uint internalPrice, uint debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );


    /* 
     * ===================================================
     * ------------------- STRUCTS -----------------------      
     * ===================================================
     */

    struct Terms {
        uint256 controlVariable; // scaling variable for price [this is used to control the price of bond to lp_token]
        uint256 vestingTerm; // in blocks
        uint256 minimumPrice; // vs principal value
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 maxDebt; // payout token decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint256 payout; // payout token remaining to be paid
        uint256 vesting; // Blocks left to vest
        uint256 lastBlock; // Last interaction
        uint256 truePricePaid; // Price paid (principal tokens per payout token) in ten-millionths - 4000000 = 0.4
        address principalToken; // this is the pricipal token bonded with
    }

    // Info for incremental adjustments to control variable 
    struct Adjust {
        bool add; // addition or subtraction
        uint256 rate; // increment
        uint256 target; // BCV when adjustment finished
        uint256 buffer; // minimum length (in blocks) between adjustments
        uint256 lastBlock; // block when last adjustment made
    }

    enum PARAMETER { VESTING, PAYOUT, DEBT }


    /* 
     * ===================================================
     * -------------------- STATE VARIABLES --------------      
     * ===================================================
     */

    IERC20 immutable payoutToken; // token paid for principal
    ITreasury immutable customTreasury; // pays for and receives principal
    mapping(address => uint256) totalPrincipalBonded; // stores the total numbers of this lp token that is bonded
    mapping(address => uint256) totalPayoutGiven; // stores the total numbers of this lp token that is bonded
    mapping(address => uint256) totalDebt;
    mapping(address => uint256) lastDecay;
    mapping(address => Terms) terms;
    mapping(address => Adjust) adjustment; // this would be used to change setting of the bond using the pricipal_token(lp) as the key
    mapping( address => Bond[] ) public bondInfo; // this is and information of the bond a user has made
    mapping(address => bool) bondActive; // this variable would be used to toogle bonding process and 

    


    /// @param _customTreasury: this is the bank where payout token and principal tokens are stored
    /// @param _initialOwner: this is the address of the protocol that has the bond contract
    constructor(
        address _customTreasury, 
        address _initialOwner
    ) {
        require( _customTreasury != address(0) );
        customTreasury = ITreasury( _customTreasury );
        payoutToken = IERC20( ITreasury(_customTreasury).bondPayoutToken());
        require( _initialOwner != address(0) );
        policy = _initialOwner;
    }



    /**
     *  @notice this function is used to add new lp token as pricipal token and to initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     *  @param _newPrincipalToken address
     */
    function initializeBond( 
        uint256 _controlVariable, 
        uint256 _vestingTerm,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _maxDebt,
        uint256 _initialDebt,
        address _newPrincipalToken
    ) external onlyPolicy() {
        require( currentDebt(_newPrincipalToken) == 0, "Debt must be 0 for initialization" );
        terms[_newPrincipalToken] = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt[_newPrincipalToken] = _initialDebt;
        lastDecay[_newPrincipalToken] = block.number;
        bondActive[_newPrincipalToken] = true;
    }


    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt(address _principalToken) public view returns ( uint ) {
        return totalDebt[_principalToken].sub( debtDecay(_principalToken) );
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay(address _pricipalToken) public view returns ( uint decay_ ) {
        uint256 blocksSinceLast = block.number.sub( lastDecay[_pricipalToken] );
        decay_ = totalDebt[_pricipalToken].mul( blocksSinceLast ).div( terms[_pricipalToken].vestingTerm );
        if ( decay_ > totalDebt[_pricipalToken] ) {
            decay_ = totalDebt[_pricipalToken];
        }
    }
    
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input, address principalAddress ) external onlyPolicy() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 10000, "Vesting must be longer than 36 hours" );
            terms[principalAddress].vestingTerm = _input;
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms[principalAddress].maxPayout = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 2
            terms[principalAddress].maxDebt = _input;
        }
    }


    /**
     *  @notice set control variable adjustment
     *  @param _addition bool
     *  @param _increment uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment ( 
        bool _addition,
        uint256 _increment, 
        uint256 _target,
        uint256 _buffer,
        address _principalToken
    ) external onlyPolicy() {
        require( _increment <= terms[_principalToken].controlVariable.mul( 30 ).div( 1000 ), "Increment too large" );

        adjustment[_principalToken] = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastBlock: block.number
        });
    }

    /// @notice this function would be used to toggle the bond state alllowing bonding and disallowing bonding 
    /// @param _principalToken: this is the address of the pricipal token you would like to edit the bonding state
    /// @param _status: this is a bool either true or false 
    function bondToggle(address _principalToken, bool _status) external onlyPolicy {
        bondActive[_principalToken] = _status;
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt(address _principalToken) internal {
        totalDebt[_principalToken] = totalDebt[_principalToken].sub( debtDecay(_principalToken) );
        lastDecay[_principalToken] = block.number;
    }

    /**
     *  @notice calculate current ratio of debt to payout token supply
     *  @notice protocols using Olympus Pro should be careful when quickly adding large %s to total supply
     *  @return debtRatio_ uint
     */
    function debtRatio(address _principalToken) public view returns ( uint debtRatio_ ) {   
        debtRatio_ = FixedPoint.fraction( 
            currentDebt(_principalToken).mul( 10 ** payoutToken.decimals() ), 
            payoutToken.totalSupply()
        ).decode112with18().div( 1e18 );
    }

    /**
     *  @notice calculate user's interest due for new bond, accounting for Olympus Fee. 
     If fee is in payout then takes in the already calcualted value. If fee is in principal token 
     than takes in the amount of principal being deposited and then calculautes the fee based on
     the amount of principal and not in terms of the payout token
     *  @param _value uint
     *  @return _payout uint
     *  @return _fee uint
     */
    function payoutFor( uint _value, address _principalToken ) public view returns ( uint256 _payout, uint256 _fee) {
        _payout = FixedPoint.fraction( _value, bondPrice(_principalToken) ).decode112with18().div( 1e11 );
    }


    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice(address _principalToken) public view returns ( uint price_ ) {        
        price_ = terms[_principalToken].controlVariable.mul( debtRatio(_principalToken) ).div( 10 ** (uint256(payoutToken.decimals()).sub(5)) );
        if ( price_ < terms[_principalToken].minimumPrice ) {
            price_ = terms[_principalToken].minimumPrice;
        }
    }

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout(address _principalToken) public view returns ( uint ) {
        return payoutToken.totalSupply().mul( terms[_principalToken].maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice(address _principalToken) internal returns ( uint price_ ) {
        price_ = terms[_principalToken].controlVariable.mul( debtRatio(_principalToken) ).div( 10 ** (uint256(payoutToken.decimals()).sub(5)) );
        if ( price_ < terms[_principalToken].minimumPrice ) {
            price_ = terms[_principalToken].minimumPrice;        
        } else if ( terms[_principalToken].minimumPrice != 0 ) {
            terms[_principalToken].minimumPrice = 0;
        }
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust(address _principalToken) internal {
        uint256 blockCanAdjust = adjustment[_principalToken].lastBlock.add( adjustment[_principalToken].buffer );
        if( adjustment[_principalToken].rate != 0 && block.number >= blockCanAdjust ) {
            uint256 initial = terms[_principalToken].controlVariable;
            if ( adjustment[_principalToken].add ) {
                terms[_principalToken].controlVariable = terms[_principalToken].controlVariable.add( adjustment[_principalToken].rate );
                if ( terms[_principalToken].controlVariable >= adjustment[_principalToken].target ) {
                    adjustment[_principalToken].rate = 0;
                }
            } else {
                terms[_principalToken].controlVariable = terms[_principalToken].controlVariable.sub( adjustment[_principalToken].rate );
                if ( terms[_principalToken].controlVariable <= adjustment[_principalToken].target ) {
                    adjustment[_principalToken].rate = 0;
                }
            }
            adjustment[_principalToken].lastBlock = block.number;
            emit ControlVariableAdjustment( initial, terms[_principalToken].controlVariable, adjustment[_principalToken].rate, adjustment[_principalToken].add );
        }
    }


    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(uint256 _amount, address _depositor, address _principalToken) external returns (uint) {
        require( _depositor != address(0), "Invalid address" );
        require(bondActive[_principalToken], "Bond not active");

        decayDebt(_principalToken);

        uint value = customTreasury.valueOfToken( address(_principalToken), _amount );

        uint payout;
        uint fee;

        (payout, fee) = payoutFor( value, _principalToken); // payout and fee is computed

        require( payout >= 10 ** payoutToken.decimals() / 100, "Bond too small" ); // must be > 0.01 payout token ( underflow protection )
        require( payout <= maxPayout(_principalToken), "Bond too large"); // size protection because there is no slippage
        
        // total debt is increased
        totalDebt[_principalToken] = totalDebt[_principalToken].add( value );

        require( totalDebt[_principalToken] <= terms[_principalToken].maxDebt, "Max capacity reached" );
                
        // depositor info is stored
        Bond memory d = Bond({ 
            // payout: bondInfo[ _depositor ][ bondInfo[ _depositor ].length].payout.add(  ),
            payout: payout,
            vesting: terms[_principalToken].vestingTerm,
            lastBlock: block.number,
            truePricePaid: bondPrice(_principalToken),
            principalToken: _principalToken
        });
        bondInfo[ _depositor ].push(d);

        totalPrincipalBonded[_principalToken] = totalPrincipalBonded[_principalToken].add(_amount); // total bonded increased
        totalPayoutGiven[_principalToken] = totalPayoutGiven[_principalToken].add(payout); // total payout increased


        customTreasury.sendPayoutTokens( payout );

        IERC20(_principalToken).safeTransferFrom( msg.sender, address(customTreasury), _amount ); // transfer principal bonded to custom treasury

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.number.add( terms[_principalToken].vestingTerm ) );
        emit BondPriceChanged( _bondPrice(_principalToken), debtRatio(_principalToken) );

        adjust(_principalToken); // control variable is adjusted
        return payout; 
    }
    

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor( address _depositor, uint256 _index ) public view returns ( uint percentVested_ ) {
        Bond memory bond = bondInfo[ _depositor ][_index];
        uint256 blocksSinceLast = block.number.sub( bond.lastBlock );
        uint256 vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = blocksSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }


    /// @notice this is a function that would be used to fetch all the bond a users has 
    /// @param _depositor: this is the depositior address 
    function fetchUserBonds(address _depositor) external view returns(Bond[] memory) {
        return bondInfo[_depositor];
    }



    /** 
     *  @notice redeem bond for user
     *  @return uint
     */ 
    function redeem(address _depositor, address _principalToken, uint256 _index) external returns (uint) {
        Bond memory info = bondInfo[ _depositor ][_index];
        uint percentVested = percentVestedFor( _depositor, _index ); // (blocks since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _depositor ][_index]; // delete user info
            emit BondRedeemed( _depositor, info.payout, 0 ); // emit bond data
            payoutToken.safeTransfer( _depositor, info.payout );
            return info.payout;
        } else { // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul( percentVested ).div( 10000 );

            // store updated deposit info
            bondInfo[ _depositor ][_index] = Bond({
                payout: info.payout.sub( payout ),
                vesting: info.vesting.sub( block.number.sub( info.lastBlock ) ),
                lastBlock: block.number,
                truePricePaid: info.truePricePaid,
                principalToken: info.principalToken
            });

            emit BondRedeemed( _depositor, payout, bondInfo[ _depositor ][_index].payout );
            payoutToken.safeTransfer( _depositor, payout );
            return payout;
        }
    }


    /**
     *  @notice calculate amount of payout token available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor, uint256 _index ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor, _index);
        uint payout = bondInfo[ _depositor ][_index].payout;

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }


}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract Ownable {

    address public policy;

    constructor () {
        policy = msg.sender;
    }

    modifier onlyPolicy() {
        require( policy == msg.sender, "Ownable: caller is not the owner" );
        _;
    }
    
    function transferManagment(address _newOwner) external onlyPolicy() {
        require( _newOwner != address(0) );
        policy = _newOwner;
    }
}