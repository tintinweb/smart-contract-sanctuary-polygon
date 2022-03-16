// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../interfaces/IProjectConfig.sol";
import "../interfaces/IPayLoanCallback.sol";
import "../interfaces/IFlashCallback.sol";
import "../interfaces/ILendVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "./IBToken.sol";

contract LendVault is ILendVault, Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IProjectConfig public configReader;

    struct BankInfo {
        bool isOpen; //
        bool canDeposit;
        bool canWithdraw;
        bool canLoan;
        uint8 interestTier; // 0-high 1-middle 2-low
        IBToken ibToken;
        uint256 totalDebt;
        uint256 totalDebtShare;
        uint256 totalReserve;
        uint256 lastInterestTime; // last update totalDebt time
    }

    mapping(address => BankInfo) public banks;
    mapping(uint256 => address) public bankIndex;
    uint256 public currentBankId;

    // [tokenAddress, debtorAddress] => debtorShare
    mapping(address => mapping(address => uint256)) public debtorShares;
    mapping(address => bool) public debtorWhitelists;

    constructor(address _projectConfig) {
        configReader = IProjectConfig(_projectConfig);
    }

    /* ========== MODIFIERS ========== */

    ///debtor whiteList
    modifier onlyDebtor {
        require(debtorWhitelists[msg.sender], "not in whiteList");
        _;
    }

    /* ========== OWNER ========== */

    function setConfig(IProjectConfig _newConfig) external onlyOwner {
        require(address(_newConfig) != address(0), "zero address");
        configReader = _newConfig;
    }

    function addBank(address tokenAddress, uint8 _interestTier, string memory _name, string memory _symbol) external onlyOwner {
        require(tokenAddress != address(0), "zero address");
        BankInfo memory bank = banks[tokenAddress];
        require(!bank.isOpen, 'bank already exists!');
        bankIndex[currentBankId] = tokenAddress;
        currentBankId += 1;

        bank.isOpen = true;
        bank.canDeposit = true;
        bank.canWithdraw = true;
        bank.canLoan = true;
        bank.interestTier = _interestTier;
        bank.totalDebt = 0;
        bank.totalDebtShare = 0;
        bank.totalReserve = 0;
        bank.lastInterestTime = block.timestamp;

        bank.ibToken = new IBToken{salt: keccak256(abi.encode(msg.sender, _name, _symbol))}(_name, _symbol);

        banks[tokenAddress] = bank;
    }

    function updateBank(
        address tokenAddress,
        bool canDeposit,
        bool canWithdraw,
        bool canLoan,
        uint8 _interestTier
    ) external onlyOwner {
        BankInfo memory bank = banks[tokenAddress];
        require(bank.isOpen, 'bank not exists!');
        bank.canDeposit = canDeposit;
        bank.canWithdraw = canWithdraw;
        bank.canLoan = canLoan;
        bank.interestTier = _interestTier;

        banks[tokenAddress] = bank;
    }

    function setDebtor(address debtorAddress, bool canBorrow) external onlyOwner {
        require(debtorAddress != address(0), "zero address");
        debtorWhitelists[debtorAddress] = canBorrow;
    }

    function reserveDistribution(address tokenAddress, uint256 amount) external onlyOwner {
        BankInfo storage bank = banks[tokenAddress];
        require(bank.totalReserve >= amount, "invalid param");
        bank.totalReserve = bank.totalReserve.sub(amount);
        emit ReserveDist(tokenAddress, amount);
    }

    function withdrawReserve(address tokenAddress, uint256 amt, address to) external onlyOwner {
        BankInfo memory bank = banks[tokenAddress];
        require(bank.totalReserve >= amt, "invalid param");
        uint256 res = bank.totalReserve;
        if(res < amt){
            amt = res;
        }
        IERC20 token = IERC20(tokenAddress);
        uint256 bal = token.balanceOf(address(this));
        if(bal < amt){
            amt = bal;
        }
        if(amt > 0){
            banks[tokenAddress].totalReserve = bank.totalReserve.sub(amt);
            token.safeTransfer(msg.sender, amt);
        }
    }

    /* ========== READABLE ========== */

    function ibShare(address tokenAddress, address user) public view override returns(uint256) {
        BankInfo memory bank = banks[tokenAddress];
        require(address(bank.ibToken) !=  address(0) , "not exist");
        return bank.ibToken.balanceOf(user);
    }

    function ibToken(address tokenAddress) public view override returns(address) {
        return address(banks[tokenAddress].ibToken);
    }

    /// the token will be borrowed, so users can only withdraw the idle balance
    function idleBalance(address tokenAddress) public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    ///
    function totalDebt(address tokenAddress) public view override returns(uint256, uint256) {
        BankInfo memory bank = banks[tokenAddress];
        return (bank.totalDebt, bank.totalDebtShare);
    }

    /// total balance（balance + debt - reserve）
    function totalBalance(address tokenAddress) public view returns(uint256) {
        BankInfo memory bank = banks[tokenAddress];
        uint256 idleBal = idleBalance(tokenAddress);
        uint256 allBal = idleBal.add(bank.totalDebt);
        if(allBal > bank.totalReserve){
            return allBal.sub(bank.totalReserve);
        }else{
            return 0;
        }
    }

    function shareToBalance(address tokenAddress, uint256 _ibAmount) public view returns(uint256) {
        uint256 totalShare = banks[tokenAddress].ibToken.totalSupply();
        if (totalShare == 0) {return _ibAmount;}
        return totalBalance(tokenAddress).mul(_ibAmount).div(totalShare);
    }

    /// @dev Return the share of the balance in the token bank.
    /// @param tokenAddress the deposit token address.
    /// @param balance the amount of the token.
    function balanceToShare(address tokenAddress, uint256 balance) public view returns(uint256) {
        uint256 totalShare = banks[tokenAddress].ibToken.totalSupply();
        if (totalShare == 0) {return balance;}
        uint256 totalBal = totalBalance(tokenAddress);
        return FullMath.mulDiv(totalShare, balance, totalBal);
    }

    /// @dev Return the balance of the share in the token bank.
    /// @param tokenAddress the deposit token address.
    /// @param share the amount of the token.
    function debtShareToBalance(address tokenAddress, uint256 share) public override view returns(uint256) {
        BankInfo memory bank = banks[tokenAddress];
        if (bank.totalDebtShare == 0) {return share;}
        return FullMath.mulDiv(bank.totalDebt ,share, bank.totalDebtShare);
    }

    /// @dev calculate debt share.
    /// @param tokenAddress the debt token address.
    /// @param balance the amount of debt.
    function balanceToDebtShare(address tokenAddress, uint256 balance) public view returns(uint256) {
        BankInfo memory bank = banks[tokenAddress];
        if (bank.totalDebt == 0) {return balance;}
        return FullMath.mulDiv(bank.totalDebtShare, balance, bank.totalDebt);
    }

    /// @dev can withdraw max share amount.
    /// @param tokenAddress the token address.
    function withdrawableShareAmount(address tokenAddress) public view returns(uint256) {
        uint256 withdrawableAmount = idleBalance(tokenAddress);
        if (withdrawableAmount == 0) {return 0;}
        uint256 pending = pendingInterest(tokenAddress);
        return banks[tokenAddress].ibToken
                                  .totalSupply()
                                  .mul(withdrawableAmount)
                                  .div(totalBalance(tokenAddress).add(pending));
    }

    /// @dev return the debtor borrow amount .
    /// @param tokenAddress the debt token address.
    /// @param debtor who borrow the token.
    function getDebt(address tokenAddress, address debtor) public view returns(uint256) {
        uint256 share = debtorShares[tokenAddress][debtor];
        if (share == 0) {return 0;}
        return debtShareToBalance(tokenAddress, share);
    }

    /// @dev how many tokens be borrowed.
    /// @param tokenAddress the debt token address.
    function utilizationRate(address tokenAddress) public view returns(uint256) {
        uint256 totalBal = totalBalance(tokenAddress);
        if (totalBal == 0) {return 0;}
        (uint256 debtBal, ) = totalDebt(tokenAddress);
        return debtBal.mul(1E20).div(totalBal); // Expand 1E20
    }

    /// @dev Return the pending interest that will be accrued in the next call.
    /// @param tokenAddress the debt token address.
    function pendingInterest(address tokenAddress) public view returns(uint256) {
        // 1、bank info
        BankInfo memory bank = banks[tokenAddress];
        require(bank.isOpen, 'bank not exists');
        // 2、time past
        uint256 timePast = block.timestamp.sub(bank.lastInterestTime);
        // 3、prevent double counting
        if (timePast == 0) {return 0;}
        // 4、rate per second
        uint256 ratePerSec = configReader.interestRate(utilizationRate(tokenAddress), bank.interestTier);
        // 5、interest = ratePerSec * timePast * totalDebt / rate
        return ratePerSec.mul(timePast).mul(bank.totalDebt).div(1E18); // rate 1E18
    }

    // interest and return debt amount and balance
    function interestAndBal(address token, uint256 share) internal returns(uint256, uint256){
        calInterest(token);
        if(share > 0){
            return (debtShareToBalance(token, share), idleBalance(token));
        }else{
            return (0, idleBalance(token));
        }
    }

    function checkPayLess(address token, uint256 beforeBal, uint256 debtValue) internal view{
        uint256 afterBal = idleBalance(token);
        require(beforeBal.add(debtValue) <= afterBal, "pay less");
    }

    function removeDebtShare(address token, uint share, uint debtValue) internal{
        BankInfo memory bank = banks[token];
        debtorShares[token][msg.sender] = debtorShares[token][msg.sender].sub(share);
        bank.totalDebtShare = bank.totalDebtShare.sub(share);
        bank.totalDebt = bank.totalDebt.sub(debtValue);
        //update
        banks[token] = bank;
    }

    /* ========== WRITEABLE ========== */

    /// @dev calculate interest and add to debt.
    /// @param tokenAddress the debt token address.
    function calInterest(address tokenAddress) internal {
        // 1、bank info
        BankInfo memory bank = banks[tokenAddress];
        require(bank.isOpen, 'bank not exists');
        // 2、interest
        uint256 interest = pendingInterest(tokenAddress);
        if (interest > 0) {
            // 3、 计算服务费
            uint256 reserve = interest.mul(configReader.interestBps()).div(10000);
            // 4、 利息添加进贷款，利滚利
            bank.totalDebt = bank.totalDebt.add(interest);
            // 5、 服务费记账为备用金
            bank.totalReserve = bank.totalReserve.add(reserve);
        }
        // 6、update time
        bank.lastInterestTime = block.timestamp;
        // update
        banks[tokenAddress] = bank;
    }

    /// @dev add more tokens to the bank then get good returns.
    /// @param tokenAddress the deposit token address.
    /// @param amount the amount of deposit token.
    function deposit(address tokenAddress, uint256 amount) external nonReentrant{
        // 1、bank info
        BankInfo memory bank = banks[tokenAddress];
        require(bank.isOpen && bank.canDeposit, 'cannot deposit');
        // 2、interest
        calInterest(tokenAddress);
        // 3、calc share
        uint256 newShare = balanceToShare(tokenAddress, amount);
        // 4、transfer
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        // 5、mint
        bank.ibToken.mint(msg.sender, newShare);
        // Event
        emit Deposit(tokenAddress, amount);

    }

    /// @dev users can withdraw their owner shares.
    /// @param tokenAddress the deposit token address.
    /// @param share the deposit share.
    function withdraw(address tokenAddress, uint256 share) external nonReentrant {
        // 1、bank info
        BankInfo memory bank = banks[tokenAddress];
        require(bank.isOpen && bank.canWithdraw, 'cannot withdraw');
        uint userShareBalance = bank.ibToken.balanceOf(msg.sender);
        require(userShareBalance > 0, "zero share!");
        if(userShareBalance < share){
            share = userShareBalance;
        }
        // 2、interest
        calInterest(tokenAddress);
        // 3、share to amount
        uint256 withdrawAmount = shareToBalance(tokenAddress, share);
        // 4、idle amount
        uint256 idleAmount = idleBalance(tokenAddress);
        // 5、withdraw amount must less idleAmount
        if (withdrawAmount > idleAmount) {
            withdrawAmount = idleAmount;
            //real withdraw share
            share = balanceToShare(tokenAddress, withdrawAmount);
        }
        // 6、burn
        bank.ibToken.burn(msg.sender, share);

        // 7、transfer
        IERC20(tokenAddress).safeTransfer(msg.sender, withdrawAmount);

        // Event
        emit Withdraw(tokenAddress, withdrawAmount);

    }

    /// @dev Debtor can borrow tokens from bank.
    /// @param tokenAddress the borrow token address.
    /// @param loanAmount the amount of loan.
    function issueLoan(address tokenAddress, uint256 loanAmount, address to) external onlyDebtor nonReentrant override returns(uint256) {
        // 1、bank info
        BankInfo memory bank = banks[tokenAddress];
        require(bank.isOpen && bank.canLoan, 'cannot issue loan');
        require(IERC20(tokenAddress).balanceOf(address(this)) >= loanAmount, 'not sufficient funds');
        // 2、interest
        calInterest(tokenAddress);
        // 3、share
        uint256 newDebtShare = balanceToDebtShare(tokenAddress, loanAmount);

        // 4、update share
        debtorShares[tokenAddress][msg.sender] = debtorShares[tokenAddress][msg.sender].add(newDebtShare);
        bank.totalDebtShare = bank.totalDebtShare.add(newDebtShare);
        bank.totalDebt = bank.totalDebt.add(loanAmount);
        // update
        banks[tokenAddress] = bank;

        // 5、transfer
        IERC20(tokenAddress).safeTransfer(to, loanAmount);

        // Event
        emit IssueLoan(tokenAddress, msg.sender, to, loanAmount);

        return newDebtShare;
    }

    /// @dev pay shareA and shareB
    function payLoan(address tokenA, address tokenB, uint256 shareA, uint256 shareB) external onlyDebtor nonReentrant override{

        // 1、check
        require(shareA > 0 || shareB > 0, "wrong share param!");
        require(shareA <= debtorShares[tokenA][msg.sender], "wrong share param!");
        require(shareB <= debtorShares[tokenB][msg.sender], "wrong share param!");
        // 2、interest and get debt value
        (uint256 debtValueA, uint256 beforeBalA) = interestAndBal(tokenA, shareA);
        (uint256 debtValueB, uint256 beforeBalB) = interestAndBal(tokenB, shareB);
        // 3、callback
        IPayLoanCallback(msg.sender).payLoanCallback(tokenA, tokenB, debtValueA, debtValueB);
        // 4、check pay result
        checkPayLess(tokenA, beforeBalA, debtValueA);
        checkPayLess(tokenB, beforeBalB, debtValueB);

        // 5、reduce share
        if(shareA > 0){
            removeDebtShare(tokenA, shareA, debtValueA);
        }
        if(shareB > 0){
            removeDebtShare(tokenB, shareB, debtValueB);
        }

        // Event
        emit PayLoan(tokenA, tokenB, msg.sender, debtValueA, debtValueB);

    }

    /// @dev Liquidate the position, if have no enough assets, we will use reserve assets to pay.
    /// @param tokenA the debt token address.
    /// @param tokenB the token witch will be used to pay loan.
    /// @param shareA the debt share.
    function liquidate(address tokenA, address tokenB, uint256 shareA, uint256 shareB) external onlyDebtor nonReentrant override{
        // 1、check
        require(shareA > 0 || shareB > 0, "wrong share!");
        require(shareA <= debtorShares[tokenA][msg.sender], "wrong share!");
        require(shareB <= debtorShares[tokenB][msg.sender], "wrong share!");
        // 2、interest
        (uint256 debtValueA, uint256 beforeBalA) = interestAndBal(tokenA, shareA);
        (uint256 debtValueB, uint256 beforeBalB) = interestAndBal(tokenB, shareB);
        // 3、callback
        IPayLoanCallback(msg.sender).payLoanCallback(tokenA, tokenB, debtValueA, debtValueB);
        // 4、Compensation for non-performing loans and reduce debt share
        uint lostA;
        uint lostB;
        if(shareA > 0){
            lostA = payLost(tokenA, beforeBalA, debtValueA);
            removeDebtShare(tokenA, shareA, debtValueA);
        }
        if(shareB > 0){
            lostB = payLost(tokenB, beforeBalB, debtValueB);
            removeDebtShare(tokenB, shareB, debtValueB);
        }

        emit Liquidate(tokenA, tokenB, msg.sender, debtValueA, debtValueB, lostA, lostB);
    }

    function payLost(address token, uint beforeBal, uint debtValue) internal returns(uint256){
        uint256 afterBal = idleBalance(token);
        beforeBal = beforeBal.add(debtValue);
        //Insufficient repayment
        if (beforeBal > afterBal) {
            uint256 lost = beforeBal.sub(afterBal);
            BankInfo memory bank = banks[token];
            if (bank.totalReserve >= lost) {
                bank.totalReserve = bank.totalReserve - lost;
            } else {
                bank.totalReserve = 0;
            }
            // update
            banks[token] = bank;
            return lost;
        }
        return 0;
    }

    /// @dev flash loan
    /// @param recipient the address who receive the fish loan money.
    /// @param tokenAddress the token witch will be used to fish loan.
    /// @param amount the debt share.
    /// @param data the customer data.
    function flash(address recipient, address tokenAddress, uint256 amount, bytes calldata data) external nonReentrant {

        // cal flash loan fee
        uint256 fee = amount.mul(configReader.flashBps()).div(10000);

        // befor Bal record
        uint256 beforeBal = idleBalance(tokenAddress);

        // transfer Token
        IERC20(tokenAddress).safeTransfer(recipient, amount);

        // callback
        IFlashCallback(msg.sender).flashCallback(fee, data);

        // check token amount
        uint256 afterBal = idleBalance(tokenAddress);
        require(beforeBal.add(fee) <= afterBal, "pay less");

        // event
        emit Flash(msg.sender, recipient, fee);

    }

    /* ========== EVENTS ========== */
    event Deposit(address indexed tokenAddress, uint256 depositAmount);
    event Withdraw(address indexed tokenAddress, uint256 withdrawAmount);
    event IssueLoan(address indexed tokenAddress, address indexed debtor, address to, uint256 loanAmount);
    event PayLoan(address indexed tokenAddress, address indexed tokenBddress, address indexed debtor, uint256 payAmtA, uint256 payAmtB);
    event Liquidate(address indexed tokenAddress, address indexed tokenBddress,
                    address indexed debtor, uint256 payAmtA, uint256 payAmtB, uint256 lostA, uint256 lostB);
    event Flash(address indexed msgSender, address indexed recipient, uint256 fee);

    event ReserveDist(address indexed tokenAddress, uint256 amount);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IProjectConfig {

    function interestBps() external view returns (uint256);

    function liquidateBps() external view returns (uint256);

    function flashBps() external view returns (uint256);

    function interestRate(uint256 utilization, uint8 tier) external view returns (uint256);

    function getOracle() external view returns (address);

    function hunter() external view returns (address);

    function onlyHunter() external view returns (bool);

    function setSecondAgo(address _poolAddress, uint8[2] memory params) external;

    function getSecondAgo(address _poolAddress) external view returns(uint8 second, uint8 num);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IPayLoanCallback {

    function payLoanCallback(address, address, uint256, uint256) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IFlashCallback {

    function flashCallback(uint256 fee, bytes calldata data) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ILendVault {

    function ibShare(address tokenAddress, address user) external view returns(uint256);

    function ibToken(address tokenAddress) external view returns(address);

    function totalDebt(address tokenAddress) external view returns(uint256, uint256);

    function issueLoan(address tokenAddress, uint256 loanAmount, address to) external returns(uint256);

    function payLoan(address tokenA, address tokenB, uint256 shareA, uint256 shareB) external;

    function liquidate(address tokenA, address tokenB, uint256 shareA, uint256 shareB) external;

    function debtShareToBalance(address tokenAddress, uint256 share) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IBToken is ERC20, Ownable{

    constructor (string memory _name, string memory _symbol) ERC20(_name, _symbol){

    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
        emit Mint(msg.sender, account, amount);
    }

    function burn(address account, uint256 value) public onlyOwner {
        _burn(account, value);
        emit Burn(msg.sender, account, value);
    }

    event Mint(address sender, address account, uint amount);
    event Burn(address sender, address account, uint amount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
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
}