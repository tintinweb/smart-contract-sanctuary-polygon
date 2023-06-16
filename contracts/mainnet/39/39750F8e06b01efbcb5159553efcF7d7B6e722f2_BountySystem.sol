//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;


/** Interfaces */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IMultiClaim {
    function multiClaim(uint256 iterations) external;
}

interface ISTS {
    function sellFeeRecipient() external view returns (address);
    function buyFeeRecipient() external view returns (address);
}

interface IFeeReceiver {
    function trigger() external;
}

interface INFT {
    function claimRewards(uint256 iterations) external;
}

contract BountySystem is Ownable {

    /** UINT */
    uint256 public iterations;
    uint256 public bountyBleed = 300; // 30% of STS in this contract

    /** ADDRESS */
    address public immutable STS;

    address public staking;
    address public farming0;
    address public farming1;
    address public NFT;

    /** BOOL */
    /** Restricts the bounty to a list of allowed wallets if true, open to the public if false */
    bool public privateBounty = true;

    /** MAPPING */
    mapping ( address => bool ) public approvedForPrivateBounty;


    /** EVENTS */
    event FarmsTriggered();
    event FeeReceiversTriggered();
    event BountyBleedSet(uint bleed);
    event IterationsSet(uint iterations);
    event PrivateBountySet(bool isPrivate);
    event NFTTriggered(uint256 nftIterations);
    event SystemTriggered(uint256 nftIterations);
    event Withdrawn(address indexed token, uint256 amount);
    event UserApprovedForPrivateBounty(address indexed user, bool isApproved);
    event AddressesSet(address staking, address farming0, address farming1, address NFT);
    event OwnerTriggered(uint256 iterations, uint256 nftIterations, uint256 bountyBleed);


    /** CONSTRUCTOR */
    constructor(address STS_, uint256 iterations_) {
        require(STS_ != address(0), 'Zero Address');
        STS = STS_;
        iterations = iterations_;
    }


    /** EXTERNAL FUNCTIONS */
    function setIsPrivateBounty(
        bool isPrivateBounty
        ) 
        external 
        onlyOwner 
    {
        privateBounty = isPrivateBounty;

        emit PrivateBountySet(isPrivateBounty);
    }

    function addToApprovedForPrivateBounty(
        address user,
        bool isApproved
        ) 
        external
        onlyOwner
    {
        approvedForPrivateBounty[user] = isApproved;
        emit UserApprovedForPrivateBounty(user, isApproved);
    }

    function setIterations(
        uint256 iterations_
        )
        external
        onlyOwner
    {
        iterations = iterations_;

        emit IterationsSet(iterations_);
    }

    function setBountyBleed(
        uint256 newBleed
        ) 
        external 
        onlyOwner 
    {
        bountyBleed = newBleed;

        emit BountyBleedSet(newBleed);
    }

    function withdraw(
        address token,
        uint256 amount
        ) 
        external
        onlyOwner 
    {
        IERC20(token).transfer(msg.sender, amount);

        emit Withdrawn(token, amount);
    }

    function setAddresses(
        address staking_,
        address farming0_,
        address farming1_,
        address NFT_
        ) 
        external 
        onlyOwner 
    {
        staking = staking_;
        farming0 = farming0_;
        farming1 = farming1_;
        NFT = NFT_;

        emit AddressesSet(staking_, farming0_, farming1_, NFT_);
    }

    function ownerTrigger(
        uint256 iterations_, 
        uint256 nftIterations_, 
        uint256 bountyBleed_
        )
        external
        onlyOwner 
    {

        // trigger fee recipients
        triggerFeeReceivers();

        // multi claim for various contracts
        IMultiClaim(staking).multiClaim(iterations_);
        IMultiClaim(farming0).multiClaim(iterations_);
        IMultiClaim(farming1).multiClaim(iterations_);

        // trigger NFT
        INFT(NFT).claimRewards(nftIterations_);

        // determine bounty bleed
        uint256 bountyReward = ( IERC20(STS).balanceOf(address(this)) * bountyBleed_ ) / 1000;
        if (bountyReward > 0) {
            IERC20(STS).transfer(msg.sender, bountyReward);
        }

        emit OwnerTriggered(iterations_, nftIterations_, bountyBleed_);
    }

    function triggerFarms() 
    external 
    {
        // ensure private bounty is preserved or not
        if (privateBounty) {
            require(approvedForPrivateBounty[msg.sender], 'Caller Not Approved To Trigger');
        }

        // trigger Fee Receivers
        triggerFeeReceivers();

        // determine bounty rewards
        uint256 bountyReward = currentBounty();

        // multi claim for various contracts
        IMultiClaim(staking).multiClaim(iterations);
        IMultiClaim(farming0).multiClaim(iterations);
        IMultiClaim(farming1).multiClaim(iterations);

        // send bounty reward to msg.sender
        if (bountyReward > 0) {
            IERC20(STS).transfer(msg.sender, bountyReward);
        }

        emit FarmsTriggered();
    }

    function triggerNFT(
        uint256 nftIterations
        ) 
        external 
    {

        // ensure private bounty is preserved or not
        if (privateBounty) {
            require(approvedForPrivateBounty[msg.sender], 'Caller Not Approved To Trigger');
        }

        INFT(NFT).claimRewards(nftIterations);

        emit NFTTriggered(nftIterations);
    }

    function triggerFeeReceivers() 
        public 
    {
        IFeeReceiver(ISTS(STS).buyFeeRecipient()).trigger();
        IFeeReceiver(ISTS(STS).sellFeeRecipient()).trigger();

        emit FeeReceiversTriggered();
    }

    function trigger(
        uint256 nftIterations
        ) 
        external 
    {

        // ensure private bounty is preserved or not
        if (privateBounty) {
            require(approvedForPrivateBounty[msg.sender], 'Caller Not Approved To Trigger');
        }

        // trigger receivers
        triggerFeeReceivers();

        // multi claim for various contracts
        IMultiClaim(staking).multiClaim(iterations);
        IMultiClaim(farming0).multiClaim(iterations);
        IMultiClaim(farming1).multiClaim(iterations);

        // trigger NFT
        INFT(NFT).claimRewards(nftIterations);

        // determine bounty rewards
        uint256 bountyReward = currentBounty();

        // send bounty reward to caller
        if (bountyReward > 0) {
            IERC20(STS).transfer(msg.sender, bountyReward);
        }

        emit SystemTriggered(nftIterations);
    }


    function currentBounty() 
        public
        view
        returns (uint256) {
            return (IERC20(STS).balanceOf(address(this)) * bountyBleed ) / 1000;
    }
}