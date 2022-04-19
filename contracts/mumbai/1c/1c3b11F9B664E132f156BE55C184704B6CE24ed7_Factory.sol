/**
 *Submitted for verification at polygonscan.com on 2022-04-18
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/interfaces/IERC20Expanded.sol

pragma solidity ^0.6.12;

interface IERC20Expanded {
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/libraries/SafeMath.sol

pragma solidity ^0.6.12;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        require(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        require(c >= _a);
        return c;
    }
}


// File contracts/interfaces/IStakingPool.sol

pragma solidity ^0.6.12;

interface IStakingPool {
    function computeUserWeight(address user) external view returns (uint256);
}


// File contracts/interfaces/IFactory.sol

pragma solidity ^0.6.12;


interface IFactory {
    function getPrivateSaleTokenPercent() external view returns (uint256);
}


// File contracts/interfaces/IRBAC.sol

pragma solidity ^0.6.12;

interface IRBAC {
    function isAdmin(address user) external view returns (bool);
}


// File contracts/interfaces/IKYC.sol

pragma solidity ^0.6.12;


interface IKYC {
    function getWhitelistStatus(address _wallet) external view returns (bool);
}


// File @openzeppelin/contracts-ethereum-package/contracts/[email protected]

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


// File @openzeppelin/contracts-ethereum-package/contracts/utils/[email protected]

pragma solidity ^0.6.0;

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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}


// File contracts/TokenPool.sol

pragma solidity ^0.6.12;







contract TokenPool is ReentrancyGuardUpgradeSafe {

    // Using SafeMath library for uint256 operations
    using SafeMath for *;

    // Contract state in terms of deposit
    enum ContractState {PENDING_SUPPLY, TOKENS_SUPPLIED, SALE_ENDED}

    // State in which is contract
    ContractState state;

    // Participation structure
    struct Participation {
        uint amountBNBPaid;
        uint amountOfTokensReceived;
        uint timestamp;
        bool isWithdrawn;
    }


    // List all participation's
    Participation [] participations;

    // Mapping if user has participated in private/public sale or not
    mapping(address => bool) public isParticipated;
    mapping(address => bool) public isParticipatedPublicSale;

    // Mapping user to his participation ids;
    mapping(address => uint256) public userToHisParticipationId;
    // Total amount of tokens sold
    uint public totalTokensSold;
    // Total BNB raised
    uint public totalMATICRaised;
    // Timestamps for private sale
    uint256 salePrivateStartTime;
    uint256 salePrivateEndTime;

    // Timestamp for public sale
    uint256 salePublicStartTime;
    uint256 salePublicEndTime;

    // Token price is quoted against MATIC token and represents how much 1 token is worth MATIC
    // So, given example: If user wants to set token price to be 0.5 BNB tokens, the token price value will be
    // 0.5 ** 10**18
    uint256 tokenPrice;
    // Allocation for private sell
    uint256 privateSellAllocation;
    // Amount sold during private sell
    uint256 privateSellTokensSold;
    // Amount of tokens user wants to sell
    uint256 amountOfTokensToSell;
    // Time at which tokens are getting unlocked
    uint256 tokensUnlockingTime;
    // Only tokens decimals supported
    uint256 public constant tokenDecimalsSupported = 18;
    // One ether in weis
    uint256 public constant one = 10**18;

    // Token which is being sold
    IERC20Expanded public tokenSold;

    IFactory public factory;
    IKYC public kycProvider;

    // Wallet address of project owner
    address public projectOwnerWallet;

    // Address of staking pool contract
    IStakingPool public stakingPool;

    event Participated(address participant, uint amountBNBParticipated, uint amountTokensBought);
    event DepositedTokens(address account, uint256 amount, uint256 privateSellAllocation, ContractState state);
    event ProjectOwnerWithdraw(address account, uint256 totalEarnings, uint256 leftover);
    event UserWithdraw(address account, uint256 amount);
    event TokensSupplied(uint amount);

    // Modifier checking if private sale is active
    modifier isPrivateSaleActive {
        require(
            block.timestamp >= salePrivateStartTime &&
            block.timestamp <= salePrivateEndTime,
            "Private sale is not active."
        );
        require(state == ContractState.TOKENS_SUPPLIED, "Wrong contract state.");
        _;
    }

    // Modifier checking if public sale is active
    modifier isPublicSaleActive {
        require(
            block.timestamp >= salePublicStartTime
            && block.timestamp <= salePublicEndTime,
            "Public sale is not active."
        );
        require(state == ContractState.TOKENS_SUPPLIED, "Wrong contract state.");
        _;
    }


    // Constructor to create contract
    constructor(
        uint256 _salePrivateStartTime,
        uint256 _salePrivateEndTime,
        uint256 _salePublicStartTime,
        uint256 _salePublicEndTime,
        uint256 _tokensUnlockingTime,
        address _tokenAddress,
        uint256 _tokenPrice,
        uint256 _amountOfTokensToSell,
        address _projectOwnerWallet,
        address _stakingPool,
        address _kycProvider
    )
    public
    {
        // Requirements for contract creation
        require(_tokenPrice > 0 , "Token price can not be 0");
        require(salePrivateEndTime > salePrivateStartTime, "End time must be greater than start time in private");
        require(salePublicEndTime > salePublicStartTime, "End time must be greater than start time in public");
        require(_tokenAddress != address(0), "_tokenAddress can not be 0x0 address.");
        require(_projectOwnerWallet != address(0), "_projectOwnerWallet can not be 0x0 address.");
        require(_stakingPool != address(0), "_stakingPool can not be 0x0 address.");
        require(_kycProvider != address(0), "_kycProvider can not be 0x0 address.");

        __ReentrancyGuard_init();

        // Private sale timestamps
        salePrivateStartTime = _salePrivateStartTime;
        salePrivateEndTime = _salePrivateEndTime;

        // Public sale timestamps
        salePublicStartTime = _salePublicStartTime;
        salePublicEndTime = _salePublicEndTime;

        // Set time after which tokens can be withdrawn
        tokensUnlockingTime = _tokensUnlockingTime;

        // Token price and amount of tokens selling
        tokenSold = IERC20Expanded(_tokenAddress);

        // Allow selling only tokens with 18 decimals
        require(tokenSold.decimals() == tokenDecimalsSupported, "Restricted only to tokens with 18 decimals.");

        tokenPrice = _tokenPrice;
        amountOfTokensToSell = _amountOfTokensToSell;

        // Wallet of project owner
        projectOwnerWallet = _projectOwnerWallet;

        // Set staking pool address inside contract
        stakingPool = IStakingPool(_stakingPool);

        // Set the KYC provider.
        kycProvider = IKYC(_kycProvider);

        // Set address of token factory
        factory = IFactory(msg.sender);

        // Set initial state to pending supply
        state = ContractState.PENDING_SUPPLY;
    }


    // Function for project owner or anyone who's in charge to deposit initial amount of tokens
    function depositTokensToSell()
    external
    nonReentrant
    {
        // This can be called only once, while contract is in the state of PENDING_SUPPLY
        require(state == ContractState.PENDING_SUPPLY, "Fund Contract : Must be in PENDING_SUPPLY state");

        // Make sure all tokens to be sold are deposited to the contract
        bool status = tokenSold.transferFrom(msg.sender, address(this), amountOfTokensToSell);
        require(status, "Transfer failed.");

        // Get current private sale percent from Factory
        uint256 privateSalePercent = factory.getPrivateSaleTokenPercent();

        // Require that percent is set properly
        require(privateSalePercent > 0 && privateSalePercent <= 100, "Invalid percent number");

        // Compute private sell allocation
        privateSellAllocation = amountOfTokensToSell.mul(privateSalePercent).div(100);

        // Mark contract state to SUPPLIED
        state = ContractState.TOKENS_SUPPLIED;

        emit DepositedTokens(msg.sender, amountOfTokensToSell, privateSellAllocation, state);
    }


    // Function to participate in private sale
    function participatePrivateSale()
    external
    payable
    isPrivateSaleActive
    nonReentrant
    {
        // only direct calls allowed
        require(msg.sender == tx.origin, "Only direct calls.");
        // Require that user can participate only once
        require(isParticipated[msg.sender] == false, "User already participated in private sale.");
        require(kycProvider.getWhitelistStatus(msg.sender), "Wallet not kyc-d.");
        // amountOfTokens = purchaseAmount / tokenPrice
        uint256 amountOfTokensBuying = (msg.value).mul(one).div(tokenPrice);
        // Compute maximal participation for user
        uint256 maximalParticipationForUser = computeMaxPrivateParticipationAmount(msg.sender);
        // Require user wants to participate with amount his staking weight allows him
        require(amountOfTokensBuying <= maximalParticipationForUser, "Overflow -> Weighting score");
        // Require that there's enough tokens
        require(
            privateSellTokensSold.add(amountOfTokensBuying) <= privateSellAllocation,
            "Overflow -> Buying more than available"
        );
        // Account sold tokens
        privateSellTokensSold = privateSellTokensSold.add(amountOfTokensBuying);
        // Internal sell tokens function
        sellTokens(msg.value, amountOfTokensBuying, 1);
        // Fire participation event
        emit Participated(msg.sender, msg.value, amountOfTokensBuying);
        // Mark that user have participated
        isParticipated[msg.sender] = true;
    }

    // Function to participate in public sale
    function participatePublicSale()
    external
    payable
    isPublicSaleActive
    nonReentrant
    {
        // only direct calls allowed
        require(msg.sender == tx.origin, "Only direct calls.");
        // Require that user can participate only once
        require(isParticipated[msg.sender], "Only users who participated in private sale can participate.");
        require(!isParticipatedPublicSale[msg.sender], "User can participate this round only once.");
        isParticipatedPublicSale[msg.sender] = true;
        // Compute how much user can participate in public sale
        uint256 publicMaxParticipation = getAmountOfTokensUserBought(msg.sender);
        // amountOfTokens = purchaseAmount / tokenPrice
        uint256 amountOfTokensBuying = (msg.value).mul(one).div(tokenPrice);
        // Require user is whitelisted and he can participate
        require(publicMaxParticipation > 0, "User is not whitelisted so he can not participate.");
        // Require public max participation is greater than amount of tokens buying
        require(publicMaxParticipation >= amountOfTokensBuying, "Contribution amount greater than max participation.");
        // Require that there's enough tokens
        require(amountOfTokensToSell.sub(totalTokensSold) > amountOfTokensBuying, "Overflow -> Buying more than available");
        // Internal sell tokens function
        sellTokens(msg.value, amountOfTokensBuying, 2);
        // Fire participation event
        emit Participated(msg.sender, msg.value, amountOfTokensBuying);
    }

    // Internal function to handle selling tokens per given price
    function sellTokens(
        uint participationAmount,
        uint amountOfTokensBuying,
        uint round
    )
    internal
    {
        // Add amount of tokens user is buying to total sold amount
        totalTokensSold = totalTokensSold.add(amountOfTokensBuying);

        // Add amount of BNBs raised
        totalMATICRaised = totalMATICRaised.add(participationAmount);

        // Meaning private sale
        if(round == 1) {
            // Compute participation id
            uint participationId = participations.length;

            // Create participation object
            Participation memory p = Participation({
                amountBNBPaid: participationAmount,
                amountOfTokensReceived: amountOfTokensBuying,
                timestamp: block.timestamp,
                isWithdrawn: false
            });

            // Push participation to array of all participations
            participations.push(p);

            // Map user to his participation ids
            userToHisParticipationId[msg.sender] = participationId;
        } else {
            uint participationId = userToHisParticipationId[msg.sender];
            Participation storage p = participations[participationId];
            p.amountOfTokensReceived = p.amountOfTokensReceived.add(amountOfTokensBuying);
            p.amountBNBPaid = p.amountBNBPaid.add(participationAmount);
        }
    }

    // Internal function to handle safe transfer
    function safeTransferBNB(
        address to,
        uint value
    )
    internal
    {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }

    function withdrawEarningsAndLeftover()
    external
    nonReentrant
    {
        require(msg.sender == projectOwnerWallet, "Restricted only to project owner.");
        // Make sure both private and public sale expired
        require(
            block.timestamp >= salePublicEndTime &&
            block.timestamp >= salePrivateEndTime,
            "Phase not finished yet."
        );

        // Earnings amount of the owner
        uint totalEarnings = address(this).balance;
        // Amount of tokens which are not sold
        uint leftover = amountOfTokensToSell.sub(totalTokensSold);

        safeTransferBNB(msg.sender, totalEarnings);

        if(leftover > 0) {
            bool status = tokenSold.transfer(msg.sender, leftover);
            require(status, "Transfer failed.");
        }

        // Set state of the contract to ENDED
        state = ContractState.SALE_ENDED;

        emit ProjectOwnerWithdraw(msg.sender, totalEarnings, leftover);
    }

    // Function where user can withdraw tokens he has bought
    function withdrawTokens()
    external
    nonReentrant
    {
        require(isParticipated[msg.sender] == true, "User is not participant.");
        require(now > tokensUnlockingTime, "Tokens are not unlocked yet.");
        // Get user participation id
        uint participationId = userToHisParticipationId[msg.sender];
        // Same unit can't be withdrawn twice
        Participation storage p = participations[participationId];
        require(p.isWithdrawn == false, "Can not withdraw same thing twice.");
        // Transfer bought tokens to address
        bool status = tokenSold.transfer(msg.sender, p.amountOfTokensReceived);
        require(status, "Transfer failed.");
        // Mark participation as withdrawn
        p.isWithdrawn = true;

        emit UserWithdraw(msg.sender, p.amountOfTokensReceived);
    }

    // Function to check user participation ids
    function getUserParticipationId(
        address user
    )
    external
    view
    returns (uint256)
    {
        return userToHisParticipationId[user];
    }

    // Function to return total number of participations
    function getNumberOfParticipations()
    external
    view
    returns (uint256)
    {
        return participations.length;
    }

    // Function to fetch high level overview of pool sale stats
    function getSaleStats()
    external
    view
    returns (uint256,uint256)
    {
        return (totalTokensSold, totalMATICRaised);
    }

    // Function to return when purchased tokens can be withdrawn
    function getTokensUnlockingTime()
    external
    view
    returns (uint)
    {
        return tokensUnlockingTime;
    }


    // Function to compute maximal private sell participation amount based on the weighting score
    function computeMaxPrivateParticipationAmount(
        address user
    )
    public
    view
    returns (uint256)
    {
        if(isParticipated[user] == true) {
            // User can participate only once
            return 0;
        }
        uint256 userWeight = stakingPool.computeUserWeight(user);
        // Compute the maximum user can participate in the private sell
        uint256 userMaxParticipation = userWeight.mul(privateSellAllocation).div(one);
        // Add 1% on top
        uint256 maxParticipation = userMaxParticipation.mul(101).div(100);
        // Compute how much tokens are left in private sell allocation
        uint256 leftoverInPrivate = privateSellAllocation.sub(privateSellTokensSold);
        // Return
        return maxParticipation > leftoverInPrivate ? leftoverInPrivate : maxParticipation;
    }

    // Function to check in which state is the contract at the moment
    function getInventoryState()
    external
    view
    returns (string memory)
    {
        if(state == ContractState.PENDING_SUPPLY) {
            return "PENDING_SUPPLY";
        }
        return "TOKENS_SUPPLIED";
    }

    // Function to get pool state depending on time and allocation
    function getPoolState()
    external
    view
    returns (string memory)
    {
        if(state == ContractState.PENDING_SUPPLY && now < salePublicEndTime) {
            return "UPCOMING";
        }
        if(now < salePrivateStartTime) {
            return "UPCOMING";
        }
        if(totalTokensSold >= amountOfTokensToSell.mul(999).div(1000)) {
            return "FINISHED";
        }
        else if (now < salePublicEndTime) {
            return "ONGOING";
        }
        return "FINISHED";
    }

    function getPoolInformation()
    external
    view
    returns (
        string memory,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        bool, // Is private sell active
        bool // is public sell active
    )
    {
        string memory tokenSymbol = tokenSold.symbol();
        bool isPrivateSellActive;
        bool isPublicSellActive;

        if(block.timestamp >= salePrivateStartTime && block.timestamp <= salePrivateEndTime) {
            isPrivateSellActive = true;
        } else if(block.timestamp >= salePublicStartTime && block.timestamp <= salePublicEndTime) {
            isPublicSellActive = true;
        }

        return (
            tokenSymbol,
            totalTokensSold,
            amountOfTokensToSell,
            salePrivateStartTime,
            salePrivateEndTime,
            salePublicStartTime,
            salePublicEndTime,
            tokenPrice,
            isPrivateSellActive,
            isPublicSellActive
        );
    }

    // Function to get participation for specific user.
    function getParticipation(
        address user
    )
    external
    view
    returns (uint,uint,uint,uint,bool)
    {
        if(isParticipated[user] == false) {
            return (0,0,0,0,false);
        }
        Participation memory p = participations[userToHisParticipationId[user]];

        return (
            p.amountBNBPaid,
            p.amountOfTokensReceived,
            p.timestamp,
            tokensUnlockingTime,
            p.isWithdrawn
        );
    }

    function getAmountOfTokensUserBought(address user) internal view returns (uint256) {
        if(!isParticipated[user]) {
            return 0;
        }
        Participation memory p = participations[userToHisParticipationId[user]];
        return p.amountOfTokensReceived;
    }

}


// File contracts/interfaces/ITokenPool.sol

pragma solidity ^0.6.12;

interface ITokenPool {
    function getPoolState() external view returns (string memory);
}


// File contracts/Factory.sol

pragma solidity ^0.6.12;



/**
 * Factory for deploying private/public sale contracts after being whitelisted
 */
contract Factory {

    using SafeMath for uint256;

    // Address of staking pool contract
    address public stakingPool;

    address public kycProvider;

    // Pointer to RBAC contract
    IRBAC rbac;

    // Storing all pools deployed in publicly visible array
    address [] poolsDeployed;

    // Mapping project owner wallet to his pools
    mapping(address => address) projectOwnerToPoolAddress;

    // Length of private sell
    uint256 public privateSellLength;

    // Length of public sell
    uint256 public publicSellLength;

    // Period of how long the tokens will be locked after purchased
    uint256 public tokensLockingPeriod;

    // Percent of tokens which are going into private sale
    uint256 privateSaleTokensPercent;

    event PoolDeployed(address _poolAddress, address _poolOwner);
    event SellLengthChanged(uint256 _sellLength);
    event TokensLockPeriodChanged(uint256 _tokensLockingPeriod);
    event RatioBetweenPrivateAndPublicChanged(uint256 _ratioPrivate);

    // Only admin modifier restricting calls only to admins registered inside RBAC contract
    modifier onlyAdmin {
        require(rbac.isAdmin(msg.sender) == true, "Restricted only to admin address.");
        _;
    }

    // Constructor to set initial values
    constructor(
        address _stakingPool,
        address _rbac,
        address _kycProvider
    )
    public
    {
        require(_stakingPool != address(0), "_stakingPool can not be 0x0 address.");
        require(_rbac != address(0), "_rbac can not be 0x0 address.");
        require(_kycProvider != address(0), "_kycProvider can not be 0x0 address.");

        stakingPool = _stakingPool;
        rbac = IRBAC(_rbac);
        kycProvider = _kycProvider;
    }

    // Function to deploy pool --> Only admin can call this
    function deployPool(
        uint256 _salePrivateStartTime,
        address _tokenAddress,
        uint256 _tokenPrice,
        uint256 _amountOfTokensToSell,
        address _projectOwnerWallet
    )
    onlyAdmin
    external
    {
        // One wallet can be mapped to at most one pool
        require(projectOwnerToPoolAddress[_projectOwnerWallet] == address(0), "Owner already has a pool.");
        require(privateSellLength > 0, "Private sale length not initialized");
        require(publicSellLength > 0, "Public sale length not initialized");

        // Compute public and private sell length (time wise)
        uint256 privateSellEndTime = _salePrivateStartTime.add(privateSellLength);
        uint256 publicSellStartTime = privateSellEndTime;
        uint256 publicSellEndTime = publicSellStartTime.add(publicSellLength);

        TokenPool tp = new TokenPool(
            _salePrivateStartTime,
            privateSellEndTime,
            publicSellStartTime,
            publicSellEndTime,
            publicSellEndTime + tokensLockingPeriod,
            _tokenAddress,
            _tokenPrice,
            _amountOfTokensToSell,
            _projectOwnerWallet,
            stakingPool,
            kycProvider
        );

        address poolAddress = address(tp);

        // Push address of newly deployed token pool to list of all addresses
        poolsDeployed.push(poolAddress);

        // Set project owner to pool address
        projectOwnerToPoolAddress[_projectOwnerWallet] = poolAddress;

        // emit event PoolDeployed
        emit PoolDeployed(poolAddress, _projectOwnerWallet);
    }

    // Function to return number of pools deployed
    function getNumberOfPoolsDeployed()
    external
    view
    returns (uint)
    {
        return poolsDeployed.length;
    }

    // Function to return all deployed pools
    function getAllPoolsDeployed()
    external
    view
    returns (address[] memory)
    {
        return poolsDeployed;
    }

    // Function to return pools per specific state
    function getPoolsPerState(
        string memory state
    )
    external
    view
    returns (address[] memory)
    {
        uint counter = 0;


        for(uint i = 0; i < poolsDeployed.length; i++) {
            ITokenPool tp = ITokenPool(poolsDeployed[i]);
            if(keccak256(abi.encodePacked(tp.getPoolState())) == keccak256(abi.encodePacked(state))) {
                counter++;
            }
        }

        address [] memory poolsInState = new address[](counter);
        uint index = 0;

        for(uint j=0; j < poolsDeployed.length; j++) {
            ITokenPool tp = ITokenPool(poolsDeployed[j]);
            if(keccak256(abi.encodePacked(tp.getPoolState())) == keccak256(abi.encodePacked(state))) {
                poolsInState[index] = poolsDeployed[j];
                index++;
            }
        }

        return poolsInState;
    }

    // Get pools, pagination enabled in order to avoid getting out of gas
    function getPools(
        uint startIndex,
        uint endIndex
    )
    external
    view
    returns (address[] memory)
    {
        uint len = endIndex.sub(startIndex);
        address [] memory pools = new address[](len);

        for(uint i = 0 ; i < len ; i++) {
            pools[i] = poolsDeployed[startIndex+i];
        }

        return pools;
    }

    // Get pools owned by specific user
    function getUserPool(
        address user
    )
    external
    view
    returns (address)
    {
        // Return pool address for this user
        return projectOwnerToPoolAddress[user];
    }

    // Function to set length of public sell
    function setPublicSellLength(
        uint256 _publicSellLength
    )
    external
    onlyAdmin
    {
        publicSellLength = _publicSellLength;
        emit SellLengthChanged(publicSellLength);
    }

    // Function to set length of private sell
    function setPrivateSellLength(
        uint256 _privateSellLength
    )
    external
    onlyAdmin
    {
        privateSellLength = _privateSellLength;
        emit SellLengthChanged(privateSellLength);
    }

    // Function to set period for how long the tokens will be locked after public sale ends
    function setTokensLockingPeriod(
        uint256 _lockPeriod
    )
    external
    onlyAdmin
    {
        tokensLockingPeriod = _lockPeriod;
        emit TokensLockPeriodChanged(tokensLockingPeriod);
    }

    // Set ratio between private and public sales
    function setRatioBetweenPrivateAndPublicSale(
        uint _privateSaleTokensPercent
    )
    external
    onlyAdmin
    {
        privateSaleTokensPercent = _privateSaleTokensPercent;
        emit RatioBetweenPrivateAndPublicChanged(privateSaleTokensPercent);
    }

    // Get private sale token percent
    function getPrivateSaleTokenPercent()
    external
    view
    returns (uint256)
    {
        return privateSaleTokensPercent;
    }

    // Function to migrate old deployed pools to the new contract
    function migrateOldPools(
        address [] memory pools,
        address [] memory projectOwners
    )
    external
    onlyAdmin
    {
        for(uint i=0; i<pools.length; i++) {
            projectOwnerToPoolAddress[projectOwners[i]] = pools[i];
            poolsDeployed.push(pools[i]);
        }
    }
}