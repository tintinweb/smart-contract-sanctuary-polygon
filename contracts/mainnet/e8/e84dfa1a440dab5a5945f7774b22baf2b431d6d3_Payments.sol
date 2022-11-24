// SPDX-License-Identifier: MIT

/*
    Created by DeNet

    WARNING:
        This token includes fees for transfers, but no fees for ProofOfStorage.
        - Transfers may used only for tests. 
        - Transfers will removed in future versions.
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./StorageToken.sol";
import "./PoSAdmin.sol";
import "./interfaces/IPayments.sol";



contract Payments is IPayments, Ownable, StorageToken, PoSAdmin {
    using SafeMath for uint256;

    uint256 private _tokensCount;
    // mapping (address =>  uint) public balances;

    constructor(
            address _address, 
            string memory _tokenName,
            string memory _tokenSymbol
    ) PoSAdmin(_address) StorageToken(_tokenName, _tokenSymbol) {}

    function getBalance(address _address) public override view returns (uint result) {
        return balanceOf(_address);
    }

    function localTransferFrom(address _from, address _to, uint _amount)  override public onlyPoS {
        require (_balances[_from]  >= _amount, "Payments:_from.balance < _amount");
        require (0  <  _amount, "Amount < 0");
        
        _balances[_from] = _balances[_from].sub(_amount, "Payments:_from.balance < _amount");
        _balances[_to] = _balances[_to].add(_amount);
        
        emit LocalTransferFrom(_from, _to, _amount);
    }

    function depositToLocal(address _user_address, uint _amount) override public onlyPoS{
        _depositByAddress(_user_address, _amount);
    }

    /**
        TODO:
            - add vesting/unlockable balance
    **/
    function closeDeposit(address _account) public override onlyPoS {
        _closeAllDeposiByAddress(_account);
    }

    function _afterSync() internal virtual override {
        super._afterSync();
        changeTokenAddress(storagePairTokenAddress);
        changeDAOAddress(daoContractAddress);
    }
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IPayments {
    event LocalTransferFrom(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );

    event RegisterToken(
        address indexed _token,
        uint256 indexed _id
    );

    function getBalance(address _address)
        external
        view
        returns (uint256 result);

    function localTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function depositToLocal(
        address _user_address,
        uint256 _amount
    ) external;

    function closeDeposit(address _user_address) external;
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet

    Contract is modifier only
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPoSAdmin.sol";
import "./interfaces/IContractStorage.sol";
import "./utils/StringNumbersConstant.sol";

contract PoSAdmin  is IPoSAdmin, Ownable, StringNumbersConstant {
    address public proofOfStorageAddress = address(0);
    address public storagePairTokenAddress = address(0);
    address public contractStorageAddress;
    address public daoContractAddress;
    address public gasTokenAddress;
    
    constructor (address _contractStorageAddress) {
        contractStorageAddress = _contractStorageAddress;
    }

    modifier onlyPoS() {
        require(msg.sender == proofOfStorageAddress, "PoSAdmin.msg.sender != POS");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoContractAddress, "PoSAdmin:msg.sender != DAO");
        _;
    }

    function changePoS(address _newAddress) public onlyOwner {
        proofOfStorageAddress = _newAddress;
        emit ChangePoSAddress(_newAddress);
    }

    function sync() public onlyOwner {
        IContractStorage contractStorage = IContractStorage(contractStorageAddress);
        proofOfStorageAddress = contractStorage.getContractAddressViaName("proofofstorage", NETWORK_ID);
        storagePairTokenAddress = contractStorage.getContractAddressViaName("pairtoken", NETWORK_ID);
        daoContractAddress = contractStorage.getContractAddressViaName("daowallet", NETWORK_ID);
        gasTokenAddress = contractStorage.getContractAddressViaName("gastoken", NETWORK_ID);
        emit ChangePoSAddress(proofOfStorageAddress);
        _afterSync();
    }

    function _afterSync() internal virtual {}
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC20Unsafe.sol";


import "./interfaces/IUserStorage.sol";
import "./interfaces/IPayments.sol";
import "./interfaces/IStorageToken.sol";
import "./utils/StringNumbersConstant.sol";
import "./PoSAdmin.sol";


/**
* @dev `feeCollector` - is cotnract created for getting some fees per storage actions.
* 
*`Warning this contract is proof of concept.`
*
* `Contract` can be updated via DeNet Improvement Proposals (DIP's)
*
* ## Starting Fees
*- User Payout Fee = 10%
*- Local Transfer's - zeor or less than User Transfer Fee.
*
* ## where does the fees go:
*- 30% of fee goes to Govermance
*- 20% of fee goes to Dapp Market Fund
*- 10% of fee goes to Miners Funding 
*- 10% of fee goes to All storage Token Holders 
*- 10% of fee goes to Referal rewards 
*
*`fees can be changed via Voting by DFILE Token in future`
*/
contract feeCollector is Ownable, StringNumbersConstant, IStorageToken{
    using SafeMath for uint256;
    using SafeMath for uint16;
    
    /* 
        Fee in TB tokne works with Minting by Transaction and Payout operations
        
        Fee calcs  by amount * fee / DIV_FEE
    */
    uint16 public payout_fee = START_PAYOUT_FEE;
    uint16 public payin_fee = START_PAYIN_FEE;
    
    uint16 public mint_percent = START_MINT_PERCENT; // 45% will minted by default if user exchange TB to PairToken. 50% will charded from user.    
    uint16 public unburn_percent = START_UNBURN_PERCENT;

    address public recipient_fee = DEFAULT_FEE_COLLECTOR;
    uint256 public fee_limit = DECIMALS_18; // 1 TB 
    uint256 public fee_collected = 0;

    address public DeNetDAOWallet;

    modifier onlyDeNetDAO() {
        require(msg.sender == DeNetDAOWallet, "PoSAdmin:msg.sender != DAO");
        _;
    }

    /**
        @dev update fee collector counter, if fee collected
    */ 
    function _addFee(uint256 amount) internal  {
        require(amount > 0);
        fee_collected = fee_collected.add(amount);
    }
    
    function calc_payout_fee(uint256 amount) public  view returns(uint256){
        return amount.mul(payout_fee).div(DIV_FEE);
    }
    
    function toFeelessPayout(uint256 amount) public view returns(uint256) {
        return amount.div(DIV_FEE.add(payout_fee.mul(unburn_percent).div(DIV_FEE))).mul(DIV_FEE);
    }
    
    function changeFeeLimit(uint new_fee_limit) public override onlyDeNetDAO {
        require(new_fee_limit > 0, "fee limit = 0");
        fee_limit = new_fee_limit;
    }

    function changeMintPercent(uint16 _newMintPercent) public override onlyDeNetDAO {
        require(_newMintPercent <= DIV_FEE, "_newMintPercent > DIV_FEE");
        mint_percent = _newMintPercent;
    }

    function changeUnburnPercent(uint16 _newUnBurnPercent) public override onlyDeNetDAO {
        require(_newUnBurnPercent <= DIV_FEE, "_newMintPercent > DIV_FEE");
        unburn_percent = _newUnBurnPercent;
    }

    function changePayoutFee(uint16 new_fee) public override onlyDeNetDAO {
        require(new_fee < DIV_FEE, "StorageToken.change_payout_fee:new_fee>=DIV_FEE");
        payout_fee = new_fee;
    }

    function changePayinFee(uint16 new_fee) public override onlyDeNetDAO {
        require(new_fee < DIV_FEE, "StorageToken.change_payin_fee:new_fee>=DIV_FEE");
        payin_fee = new_fee;
    }

    function change_recipient_fee(address _new_recipient_fee) public onlyDeNetDAO {
        require(_new_recipient_fee != address(0), "StorageToken.change_recipient_fee:_new_recipient_fee=0");
        recipient_fee = _new_recipient_fee;
    }

    /* Useful Getters */
    function currentFeeLimit() public view override returns(uint) {
        return fee_limit;
    }

    function currentPayoutFee() public view override returns(uint16) {
        return payout_fee;
    }

    function currentPayinFee() public view override returns(uint16) {
        return payin_fee;
    }

    function currentMintPercent() public view override returns(uint16) {
        return mint_percent;
    }

    function currentUnburnPercent() public view override returns(uint16) {
        return unburn_percent;
    }

    function currentDivFee() public pure override returns(uint16) {
        return DIV_FEE;
    }

    
}


contract StorageToken is  ERC20, Ownable, feeCollector{
    using SafeMath for uint256;
    using SafeMath for uint16;
    
    uint256 public pairTokenBalance = DECIMALS_18*3; // 3 DAI
    address public pairTokenAddress = PAIR_TOKEN_START_ADDRESS; // Polygon DAI
    
    /**
        @dev GasToken start rate 1 gas token = 30 pair token
    */
    constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(recipient_fee, pairTokenBalance.div(30));
    }
    
    /**
    * @dev change pair token address 
    *
    * @param _token - new pair Token Address, using for migrate from pair token to DAO.
    */
    function changeTokenAddress(address _token) internal  {
        pairTokenAddress = _token;
        _updatePairTokenBalance();
        require(pairTokenBalance > 0, "StorageToken.changeTokenAddress:pairTokenBalance=0");
    }


    /**
    * @dev need to update DAO address.
    */
    function changeDAOAddress(address _newDAO) internal {
        DeNetDAOWallet = _newDAO;
    }

    /**
    *@dev function to change name of storage token. Using, when released new token to make this token ["old"]
    *
    *@param newName - for example "Storage Size V2"
    *@param newSybmol - for example "tb-v2"
    */
    function makeThistokenOld(string calldata newName, string calldata newSybmol) public onlyDeNetDAO {
        _name = string(abi.encodePacked("[OLD] ", newName));
        _symbol = string(abi.encodePacked("OLD-", newSybmol));
    }

    function _getDepositReturns(uint256 amount) internal view returns (uint256) {
        require(amount > 0, "StorageToken._getDepositReturns:amount<=0");
        return totalSupply().mul(amount).div(pairTokenBalance).mul(DIV_FEE.sub(payin_fee)).div(DIV_FEE);
    }

    function _getDepositFeeReturns(uint256 amount) internal view returns (uint256) {
        require(amount > 0, "StorageToken._getDepositFeeReturns:amount<=0");
        return totalSupply().mul(amount).div(pairTokenBalance).mul(payin_fee.mul(mint_percent).div(DIV_FEE)).div(DIV_FEE);
    }
    

    function _getWidthdrawithReturns(uint256 amount) internal view returns (uint256) {
        amount = amount.sub(amount.mul(payout_fee.mul(DIV_FEE.sub(unburn_percent)).div(DIV_FEE)).div(DIV_FEE));
        require(amount > 0, "StorageToken._getWidthdrawithReturns:amount<=0");
        return pairTokenBalance.mul(amount).div(totalSupply());
    }

    /**
    *@dev return amount to burn orign token
    *@return toFeeCollector - amount ot feeCollector
    */
    function _getPayoutFeeAmount(uint256 amount) internal view returns (uint256) {
        require(amount > 0, "StorageToken._getPayoutBurn:amount<=0");
        return amount.mul(payout_fee).div(DIV_FEE);
    }
    function feelessBalance(address account) public view returns(uint256) {
        return _balances[account];
    }
    
    function getWidthdrawtReturns(uint256 amount) public view returns (uint256) {
        return _getWidthdrawithReturns(toFeelessPayout(amount));
    }
    
    /*
        Function to Deposit pair token
    */
    function _deposit(uint256 amount) internal {
        _depositByAddress(msg.sender, amount);
    }
    
    function _depositByAddress(address _account, uint256 amount) internal {
        IERC20 pairToken = IERC20(pairTokenAddress);
        uint balanceBefore = pairToken.balanceOf(address(this));
        require(pairToken.transferFrom(_account, address(this), amount), "StorageToken._depositByAddress:pairToken.transferFrom failed");
        uint balanceAfter = pairToken.balanceOf(address(this));
        
        // real deposited amount
        amount = balanceAfter.sub(balanceBefore);

        // calc fee to mint
        uint mintFee = _getDepositFeeReturns(amount);

        // calc returns of deposit
        uint depositReturns =_getDepositReturns(amount);

        _mint(_account, depositReturns);
        
        // add minted fee
        _mint(address(this), mintFee);
        _addFee(mintFee);
        _collectFee();

        // update pairtoken balance
        pairTokenBalance = pairTokenBalance.add(amount);
    }

    function _updatePairTokenBalance() internal {
        IERC20 PairToken = IERC20(pairTokenAddress);
        pairTokenBalance = PairToken.balanceOf(address(this));
    }
    
    function  _closeAllDeposiByAddress(address account) internal  {
        require(account != recipient_fee, "StorageToken._closeAllDeposiByAddresst:account=recipient_fee");
        _closePartOfDepositByAddress(account, feelessBalance(account));
    }
    
    function _closePartOfDeposit(uint256 amount) internal {
        _closePartOfDepositByAddress(msg.sender, amount);
    }

    function _closePartOfDepositByAddress(address account, uint amount) internal {
        require(feelessBalance(account) >= amount, "StorageToken._closePartOfDepositByAddress:account.feelessBalance<amount");

        IERC20 pairToken = IERC20(pairTokenAddress);
        uint pairToken_return = _getWidthdrawithReturns(amount);
        uint feeAmount = _getPayoutFeeAmount(amount);
        pairTokenBalance = pairTokenBalance.sub(pairToken_return);
        pairToken.transfer(account, pairToken_return);

        _burn(account, amount);
        _addFee(feeAmount);
        _mint(address(this), feeAmount);
        _collectFee();
    }
    
    function _collectFee()  internal virtual {
        if (fee_collected >= fee_limit) {
            uint contractBalance = balanceOf(address(this));

            if (contractBalance < fee_collected) {
                fee_collected = contractBalance;
            }

            _transfer(address(this), recipient_fee, fee_collected);
            fee_collected = 0;
        }
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

contract StringNumbersConstant {

   // Decimals Numbers
   uint public constant DECIMALS_18 = 1e18;
   uint public constant START_DEPOSIT_LIMIT = DECIMALS_18 * 100; // 100 DAI

   // Date and times
   uint public constant TIME_7D = 60*60*24*7;
   uint public constant TIME_1D = 60*60*24;
   uint public constant TIME_30D = 60*60*24*30;
   uint public constant TIME_1Y = 60*60*24*365;
   
   // Storage Sizes
   uint public constant STORAGE_1TB_IN_MB = 1048576;
   uint public constant STORAGE_10GB_IN_MB = 10240; // 10 GB;
  
   /**

        @notice Max blocks after proof needs to use newest proof as it possible
        For other netowrks it will be:
        @dev
        Expanse ~ 1.5H
        Ethereum ~ 54 min
        Optimistic ~ 54 min
        Ethereum Classic ~ 54 min
        POA Netowrk ~ 20 min
        Kovan Testnet ~ 16 min
        BinanceSmart Chain ~ 12.5 min
        Polygon ~ 8 min
        Avalanche ~ 8 min
   */
   uint public constant MAX_BLOCKS_AFTER_PROOF = 256;

   /*
      Polygon Network Settigns
   */
   address public constant PAIR_TOKEN_START_ADDRESS = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; // DAI in Polygon
   address public constant DEFAULT_FEE_COLLECTOR = 0x5f84192D83A49C2D7Aac6C859a7BDABf18e970b8; // DeNet Labs Polygon Multisig
   uint public constant NETWORK_ID = 137;

   /*
      StorageToken Default Vars
   */
   uint16 public constant DIV_FEE = 10000;
   uint16 public constant START_PAYOUT_FEE = 500; // 5%
   uint16 public constant START_PAYIN_FEE = 500; // 5%
   uint16 public constant START_MINT_PERCENT = 5000; // 50% from fee will minted
   uint16 public constant START_UNBURN_PERCENT = 5000; // 50% from fee will not burned
   

}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IStorageToken {

    // function balanceOf (address _user) external view returns (uint256);
    // function transfer(address recipient, uint256 amount) external returns (bool);
    // function approve(address spender, uint256 amount) external returns (bool);
    
    // useful getters
    function currentFeeLimit() external view returns (uint);
    function currentPayoutFee() external view returns (uint16);
    function currentPayinFee() external view returns (uint16);
    function currentMintPercent() external view returns (uint16);
    function currentUnburnPercent() external view returns (uint16);
    function currentDivFee() external view returns (uint16);
    
    // change interface
    function changeFeeLimit(uint _new) external;
    function changePayoutFee(uint16 _new) external;
    function changePayinFee(uint16 _new) external;
    function changeMintPercent(uint16 _new) external;
    function changeUnburnPercent(uint16 _new) external;
    
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IUserStorage {
    event ChangeRootHash(
        address indexed user_address,
        address indexed node_address,
        bytes32 new_root_hash
    );

    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );

    event ChangePaymentMethod(
        address indexed user_address,
        address indexed token
    );


    function getUserRootHash(address _user_address)
        external
        view
        returns (bytes32, uint256);

    function updateRootHash(
        address _user_address,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _nonce,
        address _updater
    ) external;

    /*
        updateLastProofTime

        Function set current timestamp yo lastProofTime in users[userAddress]. it means, that
        userDifficulty = zero (current time - lastProofTime), and will grow  with time.
    */
    function updateLastProofTime(address userAddress) external;
    
    /* 
        getPeriodFromLastProof
        function return userDifficulty.
        userDifficulty =  timestamp (curren time - lastProofTime)
    */
    function getPeriodFromLastProof(address userAddress) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public _name;
    string public _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance < zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "From zero address");
        require(recipient != address(0), "To zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IContractStorage {

    function stringToContractName(string calldata nameString) external pure returns(bytes32);

    function getContractAddress(bytes32 contractName, uint networkId) external view returns (address);

    function getContractAddressViaName(string calldata contractString, uint networkId) external view returns (address);

}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

interface IPoSAdmin {
    event ChangePoSAddress(
        address indexed newPoSAddress
    );
}

// SPDX-License-Identifier: MIT

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