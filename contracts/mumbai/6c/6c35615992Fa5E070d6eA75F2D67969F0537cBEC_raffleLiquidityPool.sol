/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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

// File: contracts/raffleLiquidityPool.sol


pragma solidity ^0.8.19;




interface raffleMethodsInterface {
    function buyRaffleTicketByLiquidity (address _to, uint256 _raffleID, uint256 _amount) external returns (bool);
    function getRaffleId () external view returns (uint256);
    function getRaffleTicketPrice (uint256 _raffleID) external view returns (uint256);
}

contract raffleLiquidityPool is Ownable {
    using Address for address;

    // ATTRIBUTES
    mapping (address => mapping (uint256 => uint256)) public balances;   // USER => (RAFFLE_ID => BALANCE)
    mapping (uint256 => uint8) public raffleStatus;                      // RAFFLE_ID => STATUS = {0 in progress; 1 canceled; 2 concluded}
    mapping (uint256 => uint256) public raffleBalance;                   // RAFFLE_ID => BALANCE

    // RAFFLE
    address public raffleAddress;
    raffleMethodsInterface raffleInstance;

    // USDT
    IERC20 public USDTInstance;

    //Liquidity Pool
    address public liquidityPoolAddress;
    uint256 public percentageToLiquidityPool = 10;

    // ##### MODIFIERS #####
    modifier safeContract (address _newContract) {
        require(_newContract != address(0), "Invalid Address");
        require(Address.isContract(_newContract), "Invalid Contract Address");
        _;
    }
    // #####################

    // ##### PUBLIC #####
    function buyTickets (uint256 _raffleID, uint256 _amount, uint256 [] memory _raffles) public {
        uint256 rafflesLength_ = _raffles.length;
        require(rafflesLength_ > 0, "No id passed");

        // check if the user has enough funds
        uint256 totalPrice_ = raffleInstance.getRaffleTicketPrice(_raffleID) * _amount;
        uint256 incrementBalance_ = totalPrice_;

        for (uint256 i = 0; i < rafflesLength_;) {
            uint256 raffle_ = _raffles[i];

            require (raffleStatus[raffle_] == 1, "Non-refundable raffle");

            if (totalPrice_ <= balances[msg.sender][raffle_]) {
                totalPrice_ = 0;
                balances[msg.sender][raffle_] -= totalPrice_;
                break;
            } else {
                totalPrice_ -= balances[msg.sender][raffle_];
                balances[msg.sender][raffle_] = 0;
            }

            unchecked{i++;}
        }

        require(totalPrice_ == 0, "Insufficient funds");

        // mint ticket
        bool ticketsMinted = raffleInstance.buyRaffleTicketByLiquidity(msg.sender, _raffleID, _amount);
        require(ticketsMinted, "Tickets not created");

        _updateBalance(msg.sender, _raffleID, incrementBalance_);
    }

    function getRefund (uint256 [] memory _raffleIDs) public {
        uint256 rafflesLength_ = _raffleIDs.length;
        require(rafflesLength_ > 0, "No id passed");

        uint256 totalRefund_ = 0;
        for (uint256 i = 0; i < rafflesLength_;) {
            uint256 raffle_ = _raffleIDs[i];

            require (raffleStatus[raffle_] == 1, "Non-refundable raffle");

            totalRefund_ += balances[msg.sender][raffle_];
            balances[msg.sender][raffle_] = 0;

            unchecked {i++;}
        }

        bool refundSent_ = USDTInstance.transfer(msg.sender, totalRefund_);
        require(refundSent_, "Transfer not completed");
    }
    // ##################

    // ##### EXTERNAL #####
    function updateBalance (address _user, uint256 _raffleID, uint256 _amount) external returns (bool) {
        require(msg.sender == raffleAddress, "Caller not approved");

        // payment
        bool paymentCompleted_ = USDTInstance.transferFrom(_user, address(this), _amount);
        require(paymentCompleted_, "Unsuccessful transfer");

        // update balances
        _updateBalance(_user, _raffleID, _amount);
        return true;
    }

    function updateRaffleStatus (uint256 _raffleID, uint8 _status) external returns (bool) {
        require(msg.sender == raffleAddress, "Caller not approved");
        require(_status > 0 && _status < 3, "Unknown status");
        require(raffleStatus[_raffleID] == 0, "Raffle already completed");

        raffleStatus[_raffleID] = _status;

        return true;
    }
    // ##################

    // ##### INTERNAL #####
    function _updateBalance (address _user, uint256 _raffleID, uint256 _amount) internal {
        balances[_user][_raffleID] += _amount;
        raffleBalance[_raffleID] += _amount;
    }

    function _paginateOutput (uint256 _page, uint256 _limit, uint256 _max) internal pure returns (uint256, uint256, uint256) {
        if (_page == 0) {
            _page = 1;
        }

        if (_limit > _max || _limit == 0) {
            _limit = _max;
        }

        uint256 skip_ = (_page - 1) * _limit;

        return (_page, _limit, skip_);
    }
    // ####################

    // ##### VIEW #####
    function getUserBalance (address _user, uint256 _page, uint256 _limit) public view returns (uint256 [] memory, uint256 [] memory, uint256) {
        uint256 raffleID_ = raffleInstance.getRaffleId();

        // pagination
        uint256 skip_ = 0;
        (_page, _limit, skip_) = _paginateOutput(_page, _limit, raffleID_);

        // search
        uint256 raffleNumber_ = 0;

        for (uint256 i = skip_; i <= skip_ + _limit; i++) {
            if (balances[_user][i] > 0 && raffleStatus[i] == 1) {
                raffleNumber_ += 1;
            }
        }

        uint256 [] memory raffles_ = new uint256[](raffleNumber_);
        uint256 [] memory balances_ = new uint256[](raffleNumber_);
        uint256 balance_ = 0;
        uint256 index_ = 0;
        address user_ = _user;  // *** STACK TOO DEEP ***

        if (raffleNumber_ == 0) {
            return (raffles_, balances_, balance_);
        }

        for (uint256 i = skip_; i <= skip_ + _limit; i++) {
           if (balances[user_][i] > 0 && raffleStatus[i] == 1) {
                raffles_[index_] = i;
                balances_[index_] = balances[user_][i];
                balance_ += balances[user_][i];
                index_ += 1;
            }
        }

        return (raffles_, balances_, balance_);
    }

    function getConcludedRaffles (uint256 _page, uint256 _limit) public view returns (uint256 [] memory, uint256 [] memory, uint256) {
        uint256 raffleID_ = raffleInstance.getRaffleId();

        // pagination
        uint256 skip_ = 0;
        (_page, _limit, skip_) = _paginateOutput(_page, _limit, raffleID_);

        // search
        uint256 raffleNumber_ = 0;

        for (uint256 i = skip_; i <= skip_ + _limit; i++) {
            if (raffleStatus[i] == 2) {
                raffleNumber_ += 1;
            }
        }

        uint256 [] memory raffles_ = new uint256[](raffleNumber_);
        uint256 [] memory balances_ = new uint256[](raffleNumber_);
        uint256 balance_ = 0;
        uint256 index_ = 0;

        if (raffleNumber_ == 0) {
            return (raffles_, balances_, balance_);
        }

        for (uint256 i = skip_; i <= skip_ + _limit; i++) {
            if (raffleStatus[i] == 2) {
                raffles_[index_] = i;
                balances_[index_] = raffleBalance[i];
                balance_ += raffleBalance[i];
                index_ += 1;
            }
        }

        return (raffles_, balances_, balance_);
    }
    // ################

    // ##### ONLY OWNER #####
    function withdraw (address _to, uint256 [] memory _raffleIDs) public onlyOwner {
        uint256 rafflesLength_ = _raffleIDs.length;
        require(rafflesLength_ > 0, "No id passed");
        uint256 total_ = 0;

        for (uint256 i = 0; i < rafflesLength_;) {
            uint256 raffle_ = _raffleIDs[i];

            if (raffleStatus[raffle_] == 2) {
                total_ += raffleBalance[raffle_];
                raffleBalance[raffle_] = 0;
            }
            
            unchecked{i++;}
        }

        require(total_ > 0, "Nothing to transfer");

        // send to liquidity
        bool sentToLiquidity_ = USDTInstance.transfer(liquidityPoolAddress, total_ * percentageToLiquidityPool / 100);
        require(sentToLiquidity_, "Transfer not completed");

        // send to `_to`
        bool sentTo_ = USDTInstance.transfer(_to, total_);
        require(sentTo_, "Transfer not completed");
    }
    // ######################

    // ##### SETTING #####
    function setRaffleAddress (address _newRaffleAddress) public onlyOwner safeContract(_newRaffleAddress){
        raffleAddress = _newRaffleAddress;
        raffleInstance = raffleMethodsInterface(_newRaffleAddress);
    }

    function setUSDTAddress (address _newUSDTAddress) public onlyOwner safeContract(_newUSDTAddress) {
        USDTInstance = IERC20(_newUSDTAddress);
    }

    function setLiquidityPoolAddress (address _newLiquidityPoolAddress) public onlyOwner {
        liquidityPoolAddress = _newLiquidityPoolAddress;
    }

    function setPercentageToLiquidityPool (uint256 _newPercentage) public onlyOwner {
        require(_newPercentage > 0 && _newPercentage < 101, "The percentage must be a number between 1 and 100 (extremes included)");
        percentageToLiquidityPool = _newPercentage;
    }
    // ###################
}