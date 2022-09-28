// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./openzepellin/Ownable.sol";
import "./openzepellin/Pausable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IterableMapping.sol";
import "./interfaces/ISablier.sol";


contract KeysCrowdsale is Ownable, Pausable {

enum CrowdsaleStage {Before,Stage1,Between,Stage2,After,Finalize}

    using IterableMapping for IterableMapping.ContributionMap;

    IterableMapping.ContributionMap private contributionMap;

    uint24 public stage1Price = 600_000; // 0.6$
    uint24 public stage2Price = 850_000; // 0.85$

    uint256 public stage1Hardcap = 250_000 * 10**18; // 250 000 KEYS
    uint256 public stage2Hardcap = 200_000 * 10**18; // 200 000 KEYS


    uint48 public stage1StartDate =  1665933518; // TODO CHANGE
    uint48 public stage1EndDate =  1675933518; // TODO CHANGE
    uint48 public stage2StartDate =  1685933518; // TODO CHANGE
    uint48 public stage2EndDate =  1695933518; // TODO CHANGE
 
    address public receiverWallet = 0x8171894d6316F73d2F69b3cA60b8633064962Ab4; // TODO CHANGE

    // Polygon USDT :address constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    // Goerli USDT : address constant USDT = 0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49;
    // Mumbai USDC : 
    address constant USDT = 0xe11A86849d99F524cAC3E7A0Ec1241828e332C62;

    bool private _isFinalized;

    IERC20 public token;
    //Sablier Goerli: 0xFc7E3a3073F88B0f249151192812209117C2014b
    ISablier public sablier;

    mapping(address => uint) private _stage1StreamId;
    mapping(address => uint) private _stage2StreamId;

    uint256 public stage1TotalContribution;
    uint256 public stage2TotalContribution;

    event Finalize();
    event DeliverTokens(uint256 startIndex, uint256 endIndex, uint256 startTime);
    event DeliverPrivateTokens(uint256 amountToDeliver_, address indexed beneficiary_, uint256 startTime_, uint256 lockTime_, uint256 vestingTime_);

    event ReceiverWalletUpdated(address indexed newWallet);

    event StagePricesUpdated(uint24 newStage1Price, uint24 newStage2Price);
    event StageHardcapsUpdated(uint256 newStage1Hardcap, uint256 newStage2Hardcap);

    event Stage1DatesUpdated(uint48 newStage1StartDate,uint48 newStage1EndDate);
    event Stage2DatesUpdated(uint48 newStage1StartDate,uint48 newStage1EndDate);

    event SablierUpdated(address indexed newSablier);

    event Buy(CrowdsaleStage stage, uint256 usdtAmount, uint256 tokens);

    constructor(address token_, address sablier_) {
        token = IERC20(token_);
        sablier = ISablier(sablier_);
    }

    function buyTokens(address beneficiary_, uint256 usdtAmount_) public whenNotPaused {
        CrowdsaleStage currentStage = getCurrentStage();
        require(currentStage == CrowdsaleStage.Stage1 || currentStage == CrowdsaleStage.Stage2, "You can't buy tokens for the moment");

        uint256 currentHardcap = getCurrentHardcap();
        uint256 currentprice = getCurrentPrice();
        uint256 stageTotalContribution = getStageTotalContribution();

        uint256 tokens = _getTokenAmount(currentprice,usdtAmount_);
        require(stageTotalContribution+tokens <= currentHardcap, "The hardcap has been reached");
        require(IERC20(USDT).transferFrom(beneficiary_,receiverWallet,usdtAmount_));
        bool isStage1 = currentStage == CrowdsaleStage.Stage1;
        contributionMap.addContribution(beneficiary_,tokens,isStage1);
        isStage1 ? stage1TotalContribution+=tokens : stage2TotalContribution+=tokens;

        emit Buy(currentStage, usdtAmount_, tokens);

    }
    function claim(address beneficiary_) external {
        require(_isFinalized,"The presale is not yet finalized");
        sablier.withdrawFromStream(_stage1StreamId[beneficiary_], getTokenClaimable(beneficiary_));
        sablier.withdrawFromStream(_stage2StreamId[beneficiary_], getTokenClaimable(beneficiary_));
    }

    function setToken(address newToken_) external onlyOwner {
        require(address(token) != newToken_, "The token has already this address");
        token = IERC20(newToken_);
    }

    function setReceiverWallet(address newWallet_) external onlyOwner {
        require(receiverWallet != newWallet_, "The receiver wallet has already this address");
        receiverWallet = newWallet_;
        emit ReceiverWalletUpdated(newWallet_);
    }

    function setStage1Dates(uint48 newStage1StartDate_, uint48 newStage1EndDate_)  external onlyOwner{
        require(newStage1StartDate_ < newStage1EndDate_, "StartDate must be lower than EndDate ");
        require(newStage1EndDate_ < stage2StartDate, "EndDate must be lower than stage2's StartDate");
        stage1StartDate = newStage1StartDate_;
        stage1EndDate = newStage1EndDate_;
        emit Stage1DatesUpdated(newStage1StartDate_,newStage1EndDate_);
    }

    function setStage2Dates(uint48 newStage2StartDate_, uint48 newStage2EndDate_)  external onlyOwner{
        require(newStage2StartDate_ < newStage2EndDate_, "StartDate must be lower than EndDate ");
        require(stage1EndDate < newStage2StartDate_, "StartDate must be greater than stage1's EndDate");
        stage2StartDate = newStage2StartDate_;
        stage2EndDate = newStage2EndDate_;
        emit Stage2DatesUpdated(newStage2StartDate_,newStage2EndDate_);
    }

    function setStageHardcaps(uint256 newStage1Hardcap_, uint256 newStage2Hardcap_)  external onlyOwner{
        require(stage1Hardcap != newStage1Hardcap_ || stage2Hardcap != newStage2Hardcap_, "Hardcaps have already these values");
        require(newStage1Hardcap_ + newStage2Hardcap_ <= token.totalSupply(), "Hardcaps have already these values");
        stage1Hardcap = newStage1Hardcap_;
        stage2Hardcap = newStage2Hardcap_;
        emit StageHardcapsUpdated(newStage1Hardcap_,newStage2Hardcap_);
    }

    function setStagePrices(uint24 newStage1Price_, uint24 newStage2Price_)  external onlyOwner{
        require(stage1Price != newStage1Price_ || stage2Price != newStage2Price_, "Prices have already these values");
        stage1Price = newStage1Price_;
        stage2Price = newStage2Price_;
        emit StagePricesUpdated(newStage1Price_,newStage2Price_);
    }

    function setSablier(address newSablier_) external onlyOwner {
        require(address(sablier) != newSablier_, "Sablier has already this address");
        sablier = ISablier(newSablier_);
        emit SablierUpdated(newSablier_);
    }

    // Index starts to 0
    function deliverTokens(uint256 startIndex_, uint256 endIndex_, uint256 startTime_) external onlyOwner{
        CrowdsaleStage currentStage = getCurrentStage();
        require(currentStage == CrowdsaleStage.After, "The presale is not yet finished");
        require(!_isFinalized, "Presale is already finalized");

        uint256 maxIndex = getTotalInvestors() -1;

        if(endIndex_ > maxIndex) endIndex_ = maxIndex;
        uint256 vestingTime = 60*60*24*300; // 10 months vesting
        uint256 stage1StartTime = startTime_;
        uint256 stage1StopTime = stage1StartTime + vestingTime;
        uint256 stage2StartTime = startTime_ + 60*60*24*90; // 3 months locking
        uint256 stage2StopTime = stage2StartTime + vestingTime;

        token.approve(address(sablier), 2**256 - 1);

        for (uint i = startIndex_; i < endIndex_; i++) {

            address key = contributionMap.getKeyAtIndex(i);

            uint256 stage1Amount = contributionMap.get(key, true);
            uint256 stage2Amount = contributionMap.get(key, false);

            if(stage1Amount != 0) {
                stage1Amount += vestingTime - (stage1Amount % vestingTime); // amount must be a multiple of vesting time
                uint256 streamId = sablier.createStream(key, stage1Amount, address(token), stage1StartTime, stage1StopTime);
                _stage1StreamId[key] = streamId;
            } if(stage2Amount != 0) {
                stage2Amount += vestingTime - (stage2Amount % vestingTime); // amount must be a multiple of vesting time
                uint256 streamId = sablier.createStream(key, stage2Amount, address(token), stage2StartTime, stage2StopTime);
                _stage2StreamId[key] = streamId;
            }
        }
        emit DeliverTokens(startIndex_,endIndex_,startTime_);
    }

    function deliverPrivateTokens(uint256 amountToDeliver_, address beneficiary_, uint256 startTime_, uint256 lockTime_, uint256 vestingTime_) external onlyOwner{
        require(!_isFinalized, "Presale is already finalized");
        require(amountToDeliver_ > 0, "Amount must be greater than 0");
        token.approve(address(sablier), 2**256 - 1);
        amountToDeliver_ += vestingTime_ - (amountToDeliver_ % vestingTime_); // amount must be a multiple of vesting time
        uint256 streamId = sablier.createStream(beneficiary_, amountToDeliver_, address(token), startTime_+ lockTime_, startTime_ + lockTime_ + vestingTime_);
        _stage1StreamId[beneficiary_] = streamId;
        emit DeliverPrivateTokens(amountToDeliver_,beneficiary_,startTime_,lockTime_,vestingTime_);

    }

    function finalize() external onlyOwner {
        require(!_isFinalized, "Presale is already finalized");
        _isFinalized = true;
        emit Finalize();
    }


    function withdrawStuckMatic(address payable to_) external onlyOwner {
        require(address(this).balance > 0, "There are no MATICs in the contract");
        to_.transfer(address(this).balance);
    }

    function withdrawStuckBEP20Tokens(address token_, address to_) external onlyOwner {
        require(IERC20(token_).balanceOf(address(this)) > 0, "There are no tokens in the contract");
        IERC20(token_).transfer(to_, IERC20(token_).balanceOf(address(this)));
    }

    // PRIVATE FUNCTIONS
    function _getTokenAmount(uint256 currentPrice_, uint256 usdtAmount_) private pure returns(uint256) {
        return (usdtAmount_ * 10**18 /currentPrice_);
    }

    // VIEW FUNCTIONS

    function getCurrentStage() public view returns(CrowdsaleStage stage) {
        // TODO Dire que Stage1 et Stage2 terminés quand hardcap a été atteint ?
        if(_isFinalized) return CrowdsaleStage.Finalize;
        else if(stage1StartDate > block.timestamp) return CrowdsaleStage.Before;
        else if(stage1StartDate <= block.timestamp && stage1EndDate >= block.timestamp) return CrowdsaleStage.Stage1;
        else if(stage1EndDate < block.timestamp && stage2StartDate > block.timestamp) return CrowdsaleStage.Between;
        else if(stage2StartDate <= block.timestamp && stage2EndDate >= block.timestamp) return CrowdsaleStage.Stage2;
        else if(stage2EndDate < block.timestamp) return CrowdsaleStage.After;

    }

    function getTokenClaimable(address _beneficiary) public view returns (uint256) {
        return sablier.balanceOf(_stage1StreamId[_beneficiary], _beneficiary) + sablier.balanceOf(_stage1StreamId[_beneficiary], _beneficiary);
    }

    function getStage1UserContribution(address _beneficiary) public view returns (uint256) {
        return contributionMap.get(_beneficiary, true);
      }

    function getStage2UserContribution(address _beneficiary) public view returns (uint256) {
        return contributionMap.get(_beneficiary, false);
      }

    function getTotalUserContribution(address _beneficiary) public view returns (uint256) {
        return getStage1UserContribution(_beneficiary) + getStage2UserContribution(_beneficiary);
      }

    function getCurrentPrice() public view returns(uint24) {
        CrowdsaleStage currentStage = getCurrentStage();
        if(currentStage == CrowdsaleStage.Stage1) return stage1Price;
        else if(currentStage == CrowdsaleStage.Stage2) return stage2Price;
        else return 0;
    }

    function getCurrentHardcap() public view returns(uint256) {
        CrowdsaleStage currentStage = getCurrentStage();
        if(currentStage == CrowdsaleStage.Stage1) return stage1Hardcap;
        else if(currentStage == CrowdsaleStage.Stage2) return stage2Hardcap;
        else return 0;
    }

    function getCurrentStageTotalContribution() public view returns(uint256) {
        CrowdsaleStage currentStage = getCurrentStage();
        if(currentStage == CrowdsaleStage.Stage1) return stage1TotalContribution;
        else if(currentStage == CrowdsaleStage.Stage2) return stage2TotalContribution;
        else return 0;
    }
    function getStageTotalContribution() public view returns(uint256) {
        return stage1TotalContribution + stage2TotalContribution;
    }

    function getTotalInvestors() public view returns(uint256) {
        return contributionMap.size();
    }

    function getUserStreamIds(address _beneficiary) public view returns(uint256,uint256) {
        return (_stage1StreamId[_beneficiary],_stage2StreamId[_beneficiary]);
    }


}

pragma solidity ^0.8.15;

// SPDX-License-Identifier: MIT License

import "./Context.sol";

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    //Locks the contract for owner for the amount of time provided (seconds)
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp> _lockTime , "Contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
     
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Context.sol";
/**
 * Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 */
  contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

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
pragma solidity ^0.8.15;

library IterableMapping {

    struct ContributionMap {
        address[] keys;
        mapping(address => uint256) stage1Values;
        mapping(address => uint256) stage2Values;
        mapping(address => uint256) indexOf; // TODO uint256 is big for simple indexes
    }


    function get(ContributionMap storage map, address key, bool isStage1) public view returns (uint256) {
        return isStage1 ?  map.stage1Values[key] : map.stage2Values[key];
    }

    function getIndexOfKey(ContributionMap storage map, address key) public view returns (int) {
        if(map.indexOf[key] == 0) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(ContributionMap storage map, uint256 index) public view returns (address) {
        return map.keys[index];
    }

    function size(ContributionMap storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function addContribution(ContributionMap storage map, address key, uint256 val, bool isStage1) public {
        if (map.indexOf[key] == 0) {
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);        
        }
        isStage1 ?  map.stage1Values[key]+=val : map.stage2Values[key]+=val;
    }

    // Je pense pas qu'on va l'utiliser
    /*function remove(ContributionMap storage map, address key) public {
        if (map.indexOf[key] ==0) {
            return;
        }
        delete map.stage1Values[key];
        delete map.stage2Values[key];
        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        map.keys[index] = lastKey;
        map.keys.pop();
    } */

}

/*contract TestIterableMap {
    using IterableMapping for IterableMapping.Stage1Contribution;
    using IterableMapping for IterableMapping.Stage2Contribution;
    IterableMapping.Stage1Contribution private stage1Contribution;
    IterableMapping.Stage2Contribution private stage2Contribution;
    function getStage1AccountContribution(address account) public view returns(uint) {
        uint data;
        for (uint i = 0; i < stage1Contribution.sizeStage1(); i++) {
            address key = stage1Contribution.getstage1KeyAtIndex(i);
            if (stage1Contribution.account[key] == account) {
                data = i;
            }
     }
     return data;
    }
    function getStage2AccountContribution(address account) public view returns(uint) {
        uint data;
        for (uint i = 0; i < stage2Contribution.sizeStage2(); i++) {
            address key = stage2Contribution.getstage2KeyAtIndex(i);
            if (stage2Contribution.account[key] == account) {
                data = i;
            }
     }
     return data;
    }
    //How to set 
    function testIterableMap() public {
        stage1Contribution.setStage1(address(0), 0xE0f992C2dAC5A9210fE5265ACAB51a023Ed39218, 0);
        stage1Contribution.setStage1(address(1), 0xE0f992C2dAC5A9210fE5265ACAB51a023Ed39218, 100);
        stage1Contribution.setStage1(address(2), 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 200);
        stage1Contribution.setStage1(address(3), 0xE0f992C2dAC5A9210fE5265ACAB51a023Ed39218, 300);
    } 
} */

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.17;

/**
 * @title ISablier
 * @author Sablier
 */
interface ISablier {
    /**
     * @notice Emits when a stream is successfully created.
     */
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );

    /**
     * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStream(uint256 indexed streamId, address indexed recipient, uint256 amount);

    /**
     * @notice Emits when a stream is successfully cancelled and tokens are transferred back on a pro rata basis.
     */
    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);

    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        );

    function createStream(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)
        external
        returns (uint256 streamId);

    function withdrawFromStream(uint256 streamId, uint256 funds) external returns (bool);

    function cancelStream(uint256 streamId) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/*
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
        return (msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}