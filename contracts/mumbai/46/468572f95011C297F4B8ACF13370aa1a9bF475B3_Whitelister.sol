pragma solidity 0.8.11;

import "./dependencies/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/dextopia/ILpDepositor.sol";
import "./interfaces/dextopia/ITopiaPartners.sol";
import "./interfaces/solidly/IBaseV1Voter.sol";
import "./interfaces/dextopia/IVeDepositor.sol";
import "./interfaces/dextopia/IFeeDistributor.sol";


contract Whitelister is IERC20, Ownable {

    string public constant name = "DexTopia Whitelisting Token";
    string public constant symbol = "TOPIA-WL";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    mapping(address => uint256) public lastEarlyPartnerMint;

    IERC20 public immutable SOLID;
    IBaseV1Voter public immutable solidlyVoter;

    ILpDepositor public lpDepositor;
    ITopiaPartners public topiaPartners;
    IVeDepositor public VeTopia;
    IFeeDistributor public feeDistributor;

    uint256 public biddingPeriodEnd;
    uint256 public highestBid;
    address public highestBidder;

    event HigestBid(address indexed user, uint256 amount);
    event NewBiddingPeriod(uint256 indexed end);
    event Whitelisted(address indexed token);

    constructor(IERC20 _solid, IBaseV1Voter _solidlyVoter) {
        SOLID = _solid;
        solidlyVoter = _solidlyVoter;
        emit Transfer(address(0), msg.sender, 0);
    }

    function setAddresses(
        ILpDepositor _lpDepositor,
        ITopiaPartners _partners,
        IVeDepositor _vetopia,
        IFeeDistributor _distributor
    ) external onlyOwner {
        lpDepositor = _lpDepositor;
        topiaPartners = _partners;
        VeTopia = _vetopia;
        feeDistributor = _distributor;

        SOLID.approve(address(_vetopia), type(uint256).max);
        VeTopia.approve(address(_distributor), type(uint256).max);

        renounceOwnership();
    }

    function approve(address _spender, uint256 _value) external override returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** shared logic for transfer and transferFrom */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @notice Transfer tokens from one address to another
        @param _from The address which you want to send tokens from
        @param _to The address which you want to transfer to
        @param _value The amount of tokens to be transferred
        @return Success boolean
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        override
        returns (bool)
    {
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        if (allowance[_from][msg.sender] != type(uint).max) {
            allowance[_from][msg.sender] -= _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }

    /**
        @notice Mint three free whitelist tokens as an early partner
        @dev Each early partner may call this once every 30 days
     */
    function earlyPartnerMint() external {
        require(topiaPartners.isEarlyPartner(msg.sender), "Not an early partner");
        require(lastEarlyPartnerMint[msg.sender] + 86400 * 30 < block.timestamp, "One mint per month");

        lastEarlyPartnerMint[msg.sender] = block.timestamp;
        balanceOf[msg.sender] += 3e18;
        totalSupply += 3e18;
        emit Transfer(address(0), msg.sender, 3e18);
    }

    function isActiveBiddingPeriod() public view returns (bool) {
        return biddingPeriodEnd >= block.timestamp;
    }

    function canClaimFinishedBid() public view returns (bool) {
        return biddingPeriodEnd > 0 && biddingPeriodEnd < block.timestamp;
    }

    function minimumBid() public view returns (uint256) {
        if (isActiveBiddingPeriod()) {
            return highestBid * 101 / 100;
        }
        uint256 fee = solidlyVoter.listingFee();
        // quote 0.1% higher as ve expansion between quote time and submit time can change listingFee
        return fee / 10 + (fee / 1000);
    }

    function _minimumBid() internal view returns (uint256) {
        if (isActiveBiddingPeriod()) {
            return highestBid * 101 / 100;
        }
        return solidlyVoter.listingFee() / 10;
    }

    /**
        @notice Bid to purchase a whitelist token with SOLID
        @dev Each bidding period lasts for three days. The initial bid must be
             at least 10% of the current solidly listing fee. Subsequent bids
             must increase the bid by at least 1%. The full SOLID amount is
             transferred from the bidder during the call, and the amount taken
             from the previous bidder is refunded.
        @param amount Amount of SOLID to bid
     */
    function bid(uint256 amount) external {
        require(amount >= _minimumBid(), "Below minimum bid");

        if (canClaimFinishedBid()) {
            // if the winning bid from the previous period was not claimed,
            // execute it prior to starting a new period
            claimFinishedBid();
        } else if (highestBid != 0) {
            // if there is already a previous bid, return it to the bidder
            SOLID.transfer(highestBidder, highestBid);
        }

        if (biddingPeriodEnd == 0) {
            // if this is the start of a new period, set the end as +3 days
            biddingPeriodEnd = block.timestamp + 86400 * 3;
            emit NewBiddingPeriod(biddingPeriodEnd);
        }

        // transfer SOLID from the caller and record them as the highest bidder
        SOLID.transferFrom(msg.sender, address(this), amount);
        highestBid = amount;
        highestBidder = msg.sender;
        emit HigestBid(msg.sender, amount);
    }

    /**
        @notice Mint a new whitelist token for the highest bidder in the finished period
        @dev Placing a bid to start a new period will also triggers a claim
     */
    function claimFinishedBid() public {
        require(biddingPeriodEnd > 0 && biddingPeriodEnd < block.timestamp, "No pending claim");

        VeTopia.depositTokens(highestBid);
        feeDistributor.depositFee(address(VeTopia), highestBid);

        balanceOf[highestBidder] += 1e18;
        totalSupply += 1e18;

        highestBid = 0;
        highestBidder = address(0);
        biddingPeriodEnd = 0;

        emit Transfer(address(0), highestBidder, 1e18);
    }

    /**
        @notice Whitelist a new token in Solidly
        @dev This function burns 1 whitelist token from the caller's balance
        @param token Address of the token to whitelist
    */
    function whitelist(address token) external {
        require(balanceOf[msg.sender] >= 1e18, "Insufficient balance");

        balanceOf[msg.sender] -= 1e18;
        totalSupply -= 1e18;
        emit Transfer(msg.sender, address(0), 1e18);

        lpDepositor.whitelist(token);
        emit Whitelisted(token);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
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
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

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

pragma solidity 0.8.11;

interface ILpDepositor {
    function setTokenID(uint256 tokenID) external returns (bool);
    function userBalances(address user, address pool) external view returns (uint256);
    function totalBalances(address pool) external view returns (uint256);
    function transferDeposit(address pool, address from, address to, uint256 amount) external returns (bool);
    function whitelist(address token) external returns (bool);
}

pragma solidity 0.8.11;

interface ITopiaPartners {
    function earlyPartnerPct() external view returns (uint256);
    function isEarlyPartner(address account) external view returns (bool);
}

pragma solidity 0.8.11;

interface IBaseV1Voter {
    function bribes(address gauge) external view returns (address bribe);
    function gauges(address pool) external view returns (address gauge);
    function poolForGauge(address gauge) external view returns (address pool);
    function createGauge(address pool) external returns (address);
    function vote(uint tokenId, address[] calldata pools, int256[] calldata weights) external;
    function whitelist(address token, uint tokenId) external;
    function listingFee() external view returns (uint256);
    function _ve() external view returns (address);
    function isWhitelisted(address pool) external view returns (bool);
}

pragma solidity 0.8.11;

import "../IERC20.sol";

interface IVeDepositor is IERC20 {
    function depositTokens(uint256 amount) external returns (bool);
}

pragma solidity 0.8.11;

interface IFeeDistributor {
    function depositFee(address _token, uint256 _amount) external returns (bool);
}