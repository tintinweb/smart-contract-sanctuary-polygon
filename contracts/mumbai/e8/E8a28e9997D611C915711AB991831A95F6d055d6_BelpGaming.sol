/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
    // function renounceOwnership() public virtual onlyOwner {
    //     _setOwner(address(0));
    // }

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

    constructor() {
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


contract BelpGaming is Ownable, ReentrancyGuard {

    /* ========== STRUCT ========== */

    // tiers
    enum Tier {
        tier1,
        tier2,
        tier3,
        tier4,
        tier5
    }
    // gamer info
    struct GamerInfo {
        address to;
        bool hasReward;
        Tier tier;
    }

    event SetRewardForTier(address indexed owner, address token, uint256 _reward, uint256 _maxReward, Tier _tier);
    event SetReward(address indexed owner, address[] _listAddress, Tier _tier);
    event WithdrawMatic(address indexed owner);
    event WithdrawTier1(address indexed owner);
    event WithdrawTier2(address indexed owner);
    event WithdrawTier3(address indexed owner);
    event WithdrawTier4(address indexed owner);
    event WithdrawTier5(address indexed owner);
    event Claim(address indexed owner);
    event UpdateGamerInfo(address indexed owner, address _to, bool _hasReward, Tier _tier);

    /* ========== VARIABLES ========== */
    IERC20 public tier1Token = IERC20(0xDa01c268A92f6E02b8CcadCF76B3a88b1E69CD09);
    IERC20 public tier2Token = IERC20(0xe38F8B1ab6EC9F058C02B214227b954d6A0E3796);
    IERC20 public tier3Token = IERC20(0xA47e0e7BbebE9E83801e6624909A388B822a6849);
    IERC20 public tier4Token = IERC20(0xB6b9Dd561CA60f1E812C946a4fA7352873044D51);
    IERC20 public tier5Token = IERC20(0xFa235724563a8555bbF7093E52959B0d471B04B7);

    uint256 public rewardTier1 = 1 ether;
    uint256 public rewardTier2 = 2 ether;
    uint256 public rewardTier3 = 3 ether;
    uint256 public rewardTier4 = 4 ether;
    uint256 public rewardTier5 = 5 ether;
 
    uint256 public maxRewardForTier1 = 200;
    uint256 public maxRewardForTier2 = 100;
    uint256 public maxRewardForTier3 = 50;
    uint256 public maxRewardForTier4 = 20;
    uint256 public maxRewardForTier5 = 10;

    GamerInfo[] public gamerTier1;
    GamerInfo[] public gamerTier2;
    GamerInfo[] public gamerTier3;
    GamerInfo[] public gamerTier4;
    GamerInfo[] public gamerTier5;

    /* ========== VIEWS ========== */

    /**
     * @dev Function to get gamer info
     */
    function getGamerInfo(address to) public view returns(address,bool,Tier) {
        (uint256 gamerIndex,Tier tier) = getGamerIndex(to);
        require(gamerIndex != 9999, "gamer not found");
        GamerInfo memory gamerInfo;

        if(tier == Tier.tier1) {
            gamerInfo = gamerTier1[gamerIndex];
        } else if (tier == Tier.tier2) {
            gamerInfo = gamerTier2[gamerIndex];
        } else if (tier == Tier.tier3) {
            gamerInfo = gamerTier3[gamerIndex];
        } else if (tier == Tier.tier4) {
            gamerInfo = gamerTier4[gamerIndex];
        } else if (tier == Tier.tier5) {
            gamerInfo = gamerTier5[gamerIndex];
        }

        return (gamerInfo.to, gamerInfo.hasReward, gamerInfo.tier);
    }

    /**
     * @dev Function to get balance tier1 of contract
     */
    function balanceTier1() public view returns(uint256) {
        return tier1Token.balanceOf(address(this));
    }

    /**
     * @dev Function to get balance tier2 of contract
     */
    function balanceTier2() public view returns(uint256) {
        return tier2Token.balanceOf(address(this));
    }

    /**
     * @dev Function to get balance tier3 of contract
     */
    function balanceTier3() public view returns(uint256) {
        return tier3Token.balanceOf(address(this));
    }

    /**
     * @dev Function to get balance tier4 of contract
     */
    function balanceTier4() public view returns(uint256) {
        return tier4Token.balanceOf(address(this));
    }

    /**
     * @dev Function to get balance tier5 of contract
     */
    function balanceTier5() public view returns(uint256) {
        return tier5Token.balanceOf(address(this));
    }

    /**
     * @dev Function to get balance matic of contract
     */
    function balanceMATIC() public view returns(uint256) {
        return address(this).balance;
    }

    /**
     * @dev Function to get number of gamer in tier 1
     */
    function numberOfTier1() public view returns(uint256) {
        return gamerTier1.length;
    }

    /**
     * @dev Function to get number of gamer in tier 2
     */
    function numberOfTier2() public view returns(uint256) {
        return gamerTier2.length;
    }

    /**
     * @dev Function to get number of gamer in tier 3
     */
    function numberOfTier3() public view returns(uint256) {
        return gamerTier3.length;
    }

    /**
     * @dev Function to get number of gamer in tier 4
     */
    function numberOfTier4() public view returns(uint256) {
        return gamerTier4.length;
    }

    /**
     * @dev Function to get number of gamer in tier 5
     */
    function numberOfTier5() public view returns(uint256) {
        return gamerTier5.length;
    }

    /**
     * @dev Function to get gamer index
     */
    function getGamerIndex(address _to) public view returns(uint256,Tier) {
        for(uint256 i = 0; i < gamerTier1.length; i++) {
            if(gamerTier1[i].to == _to) {
                return (i,gamerTier1[i].tier);
            }
        }
        for(uint256 i = 0; i < gamerTier2.length; i++) {
            if(gamerTier2[i].to == _to) {
                return (i,gamerTier1[i].tier);
            }
        }
        for(uint256 i = 0; i < gamerTier3.length; i++) {
            if(gamerTier3[i].to == _to) {
                return (i,gamerTier1[i].tier);
            }
        }
        for(uint256 i = 0; i < gamerTier4.length; i++) {
            if(gamerTier4[i].to == _to) {
                return (i,gamerTier1[i].tier);
            }
        }
        for(uint256 i = 0; i < gamerTier5.length; i++) {
            if(gamerTier5[i].to == _to) {
                return (i,gamerTier1[i].tier);
            }
        }

        return (9999,Tier.tier1);
    }

    /**
     * @dev Function to check valid address
     */
    function checkValidAddress(address _to, Tier _tier) public view returns(bool) {
        if(_tier == Tier.tier1) {
            if(numberOfTier1() >= maxRewardForTier1) {
                return false;
            }
            for(uint256 i = 0; i < gamerTier1.length; i++) {
                if(gamerTier1[i].to == _to && gamerTier1[i].hasReward == true) {
                    return false;
                }
            }
        } else if (_tier == Tier.tier2) {
            if(numberOfTier2() >= maxRewardForTier2) {
                return false;
            }
            for(uint256 i = 0; i < gamerTier2.length; i++) {
                if(gamerTier2[i].to == _to && gamerTier2[i].hasReward == true) {
                    return false;
                }
            }
        } else if (_tier == Tier.tier3) {
            if(numberOfTier3() >= maxRewardForTier3) {
                return false;
            }
            for(uint256 i = 0; i < gamerTier3.length; i++) {
                if(gamerTier3[i].to == _to && gamerTier3[i].hasReward == true) {
                    return false;
                }
            }
        } else if (_tier == Tier.tier4) {
            if(numberOfTier4() >= maxRewardForTier4) {
                return false;
            }
            for(uint256 i = 0; i < gamerTier4.length; i++) {
                if(gamerTier4[i].to == _to && gamerTier4[i].hasReward == true) {
                    return false;
                }
            }
        } else if (_tier == Tier.tier5) {
            if(numberOfTier5() >= maxRewardForTier5) {
                return false;
            }
            for(uint256 i = 0; i < gamerTier5.length; i++) {
                if(gamerTier5[i].to == _to && gamerTier5[i].hasReward == true) {
                    return false;
                }
            }
        }

        return true;
    }

    /**
     * @dev Function to check valid reward code
     */
    function checkValidReward(address _to, Tier _tier) public view returns(bool) {
        if(_tier == Tier.tier1) {
            for(uint256 i = 0; i < gamerTier1.length; i++) {
                if(gamerTier1[i].to == _to && gamerTier1[i].hasReward == true) {
                    return true;
                }
            }
        } else if (_tier == Tier.tier2) {
            for(uint256 i = 0; i < gamerTier2.length; i++) {
                if(gamerTier2[i].to == _to && gamerTier2[i].hasReward == true) {
                    return true;
                }
            }
        } else if (_tier == Tier.tier3) {
            for(uint256 i = 0; i < gamerTier3.length; i++) {
                if(gamerTier3[i].to == _to && gamerTier3[i].hasReward == true) {
                    return true;
                }
            }
        } else if (_tier == Tier.tier4) {
            for(uint256 i = 0; i < gamerTier4.length; i++) {
                if(gamerTier4[i].to == _to && gamerTier4[i].hasReward == true) {
                    return true;
                }
            }
        } else if (_tier == Tier.tier5) {
            for(uint256 i = 0; i < gamerTier5.length; i++) {
                if(gamerTier5[i].to == _to && gamerTier5[i].hasReward == true) {
                    return true;
                }
            }
        }

        return false;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Function to deposit MATIC.
     */
    function deposit() external payable onlyOwner {
        
    }

    /**
     * @dev Function to withdraw Matic.
     */
    function withdrawMatic() external onlyOwner {
        payable(owner()).transfer(address(this).balance);

        emit WithdrawMatic(msg.sender);
    }

    /**
     * @dev Function to withdraw Tier1.
     */
    function withdrawTier1() external onlyOwner {
        uint256 bal = balanceTier1();
        require(bal > 0, "you dont have a Tier1 token");
        tier1Token.transfer(owner(), bal);

        emit WithdrawTier1(msg.sender);
    }

    /**
     * @dev Function to withdraw Tier2.
     */
    function withdrawTier2() external onlyOwner {
        uint256 bal = balanceTier2();
        require(bal > 0, "you dont have a Tier2 token");
        tier2Token.transfer(owner(), bal);

        emit WithdrawTier1(msg.sender);
    }

    /**
     * @dev Function to withdraw Tier3.
     */
    function withdrawTier3() external onlyOwner {
        uint256 bal = balanceTier3();
        require(bal > 0, "you dont have a Tier3 token");
        tier3Token.transfer(owner(), bal);

        emit WithdrawTier3(msg.sender);
    }

    /**
     * @dev Function to withdraw Tier4.
     */
    function withdrawTier4() external onlyOwner {
        uint256 bal = balanceTier4();
        require(bal > 0, "you dont have a Tier4 token");
        tier4Token.transfer(owner(), bal);

        emit WithdrawTier4(msg.sender);
    }

    /**
     * @dev Function to withdraw Tier5.
     */
    function withdrawTier5() external onlyOwner {
        uint256 bal = balanceTier5();
        require(bal > 0, "you dont have a Tier5 token");
        tier5Token.transfer(owner(), bal);

        emit WithdrawTier5(msg.sender);
    }

    /**
     * @dev Function to update gamer info.
     * @param _to is a address.
     * @param _hasReward is a check if address has reward or not.
     * @param _tier is a tier type.
     */
    function updateGamerInfo(address _to, bool _hasReward, Tier _tier) external onlyOwner {
        require(_to != address(0),"sender is zero address");
        (uint256 gamerIndex,Tier tier) = getGamerIndex(_to);
        require(gamerIndex != 9999, "gamer not found");
        GamerInfo memory gamerInfo;

        if(tier == Tier.tier1) {
            gamerInfo = gamerTier1[gamerIndex];
        } else if (tier == Tier.tier2) {
            gamerInfo = gamerTier2[gamerIndex];
        } else if (tier == Tier.tier3) {
            gamerInfo = gamerTier3[gamerIndex];
        } else if (tier == Tier.tier4) {
            gamerInfo = gamerTier4[gamerIndex];
        } else if (tier == Tier.tier5) {
            gamerInfo = gamerTier5[gamerIndex];
        }

        gamerInfo.to = _to;
        gamerInfo.hasReward = _hasReward;
        gamerInfo.tier = _tier;
        
        emit UpdateGamerInfo(msg.sender, _to, _hasReward, _tier);
    }

    /**
     * @dev Function to set the number of reward token for tier.
     * @param _token is a new reward token.
     * @param _reward is a new number of reward token.
     * @param _maxReward is a new max of reward token.
     * @param _tier is a tier type.
     */
    function setRewardForTier(address _token, uint256 _reward, uint256 _maxReward, Tier _tier) external onlyOwner {
        require(_token != address(0),"token is zero address");
        require(_reward > 0,"_token must greater than zero");
        if(_tier == Tier.tier1) {
            tier1Token = IERC20(_token);
            rewardTier1 = _reward;
            maxRewardForTier1 = _maxReward;
        } else if (_tier == Tier.tier2) {
            tier2Token = IERC20(_token);
            rewardTier2 = _reward;
            maxRewardForTier2 = _maxReward;
        } else if (_tier == Tier.tier3) {
            tier3Token = IERC20(_token);
            rewardTier3 = _reward;
            maxRewardForTier3 = _maxReward;
        } else if (_tier == Tier.tier4) {
            tier4Token = IERC20(_token);
            rewardTier4 = _reward;
            maxRewardForTier4 = _maxReward;
        } else if (_tier == Tier.tier5) {
            tier5Token = IERC20(_token);
            rewardTier5 = _reward;
            maxRewardForTier5 = _maxReward;
        }
        
        emit SetRewardForTier(msg.sender, _token, _reward, _maxReward, _tier);
    }

    /**
     * @dev Function to set reward code
     * @param _listAddress is a list user will receive reward.
     * @param _tier is a tier type.
     */
    function setReward(address[] calldata _listAddress, Tier _tier) external onlyOwner {
        require(_listAddress.length > 0, "no address select");
        for(uint256 i = 0; i < _listAddress.length; i++) {
            if(checkValidAddress(_listAddress[i], _tier)) {
                if(_tier == Tier.tier1) {
                    gamerTier1.push(GamerInfo({
                        to: _listAddress[i],
                        hasReward: true,
                        tier: _tier
                    }));
                } else if (_tier == Tier.tier2) {
                    gamerTier2.push(GamerInfo({
                        to: _listAddress[i],
                        hasReward: true,
                        tier: _tier
                    }));
                } else if (_tier == Tier.tier3) {
                    gamerTier3.push(GamerInfo({
                        to: _listAddress[i],
                        hasReward: true,
                        tier: _tier
                    }));
                } else if (_tier == Tier.tier4) {
                    gamerTier4.push(GamerInfo({
                        to: _listAddress[i],
                        hasReward: true,
                        tier: _tier
                    }));
                } else if (_tier == Tier.tier5) {
                    gamerTier5.push(GamerInfo({
                        to: _listAddress[i],
                        hasReward: true,
                        tier: _tier
                    }));
                }
            }
        }

        emit SetReward(msg.sender, _listAddress, _tier);
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @dev Function to claim
     */
    function claim() public nonReentrant {
        (uint256 gamerIndex,Tier tier) = getGamerIndex(_msgSender());
        require(gamerIndex != 9999, "gamer not found");
        require(checkValidReward(_msgSender(), tier), "you dont have a reward");

        if(tier == Tier.tier1) {
            GamerInfo memory gamerInfo = gamerTier1[gamerIndex];
            tier1Token.transfer(gamerInfo.to, rewardTier1);
            delete gamerTier1[gamerIndex];
        } else if (tier == Tier.tier2) {
            GamerInfo memory gamerInfo = gamerTier2[gamerIndex];
            tier2Token.transfer(gamerInfo.to, rewardTier2);
            delete gamerTier2[gamerIndex];
        } else if (tier == Tier.tier3) {
            GamerInfo memory gamerInfo = gamerTier3[gamerIndex];
            tier3Token.transfer(gamerInfo.to, rewardTier3);
            delete gamerTier3[gamerIndex];
        } else if (tier == Tier.tier4) {
            GamerInfo memory gamerInfo = gamerTier4[gamerIndex];
            tier4Token.transfer(gamerInfo.to, rewardTier4);
            delete gamerTier4[gamerIndex];
        } else if (tier == Tier.tier5) {
            GamerInfo memory gamerInfo = gamerTier5[gamerIndex];
            tier5Token.transfer(gamerInfo.to, rewardTier5);
            delete gamerTier5[gamerIndex];
        }

        emit Claim(msg.sender);
    }

}