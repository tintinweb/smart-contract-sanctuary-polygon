/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
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
    constructor(address _owner) {
        owner = _owner;
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
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
     * by making the `nonReentrant` function external, and making it call a
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

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IEVEOTCStakes {
    function getOptionDiscount(address user) external view returns (uint8 _discount_seller, uint8 _discount_buyer);
}

interface IEVEOTC {
    struct Token {address token; uint256 cmc_index; address chanlink_aggregator; uint256 manual_entry_price; uint256 last_update; uint256 last_price;}
    function tokens(uint256 index) external returns (Token memory);
    function tokens_length() external returns (uint256);
    function tokens_enabled(address _add) external returns (bool);
    function token_indexes(address _add) external view returns(int index);
    function getColdUSDPrice(address _token) external view returns (uint256 price);
    function getUSDPrice(address _token) external returns (uint256 price);
}

contract EVEOTCOptionsLending is Owner, ReentrancyGuard {
    
    // Accepted stable coins
    IERC20[] public stable_coins;

    // available stable coins
    mapping(address => bool) public stableCoinsAvailable;

    // commissions to pay to EVE Exchange
    // those are percentages with two decimals, example: 50 means 0,5%, 300 means 3%
    uint32 public commission_premium;   // premium commission
    uint32 public commission_sell;      // sellers commission
    uint32 public commission_lending;   // EVE's commission for lending
    uint32 public commission_pool;      // pool's commission for lending

    // minium threshold of profitability in the lending checking
    // 101 means 1% profits
    // 103 = 3% profits (default)
    uint16 public pool_min_profit = 103;

    // external smart contracts
    IEVEOTCStakes public stakes;
    IEVEOTC public eveOtc;

    // wallet of the owner to receive funds
    address public owner_wallet;

    /**
     *
     * Option:
     *
     * @param call: it is a call option (true) or a put option (false)
     * @param seller: the user that is selling the token
     * @param token: token exchanged for USD
     * @param premium: price to pay to get the right to buy or sell this option
     * @param amount: amount of token 
     * @param strike: USD price of token including 8 decimals digits
     * @param created: timestamp
     * @param expiry: option expiration time in seconds
     * @param buyer: the user buying the token
     * @param premiumPaid: premium was paid (true) or not (false)
     * @param optionPaid: the option was paid and closed (true) or not (false)
     * @param canceled: if the option was cancelled (true) or it is still active (false)
     *
     * User story:
     *
     * Mike is sells a call option for 1000 Matic at $1 strike / $100 Premium that expires in 30 days
     *
     *   call: true
     *   seller: Mike
     *   token: Matic
     *   premium: $100 (always in USD)
     *   amount: 1000 (with token decimals included)
     *   strike: 1 (price in USD with eight decimal digits)
     *   created: today
     *   expire: today +30 days
     *
     * Bob buys the option for $100 - he pays the premium
     *
     *   buyer: Bob
     *   premiumPaid: true
     *   optionPaid: false
     *
     * commissionSell: backup commission sell percentage (from 0 to 10000 at the momento of option creation)
     *
     */
    struct Option {
        bool call;
        address seller;
        IERC20 token;
        uint256 premium;
        uint256 amount;
        uint256 strike;
        uint256 created;
        uint256 expiry;
        address buyer;
        bool premiumPaid;
        bool optionPaid;
        bool canceled;
    }

    // all system offers, historical and active
    Option[] public options;

    // tokens used to settle Options
    mapping(uint256 => IERC20) public settleTokens;

    event NewOption(
        bool call,
        uint256 index,
        address seller,
        IERC20 token,
        uint256 premium,
        uint256 amount,
        uint256 strike,
        uint256 created,
        uint256 expiry
    );

    event PayPremium(
        uint256 index,
        address buyer,
        uint256 paid,
        uint256 commission
    );

    event CancelOption(
        uint256 index
    );

    event Settle(uint256 index, address coin);
    event SettleWithLending(uint256 index, bool call, uint256 tokenPrice, uint256 profit, uint256 addedToPool, uint256 eveCommission, uint256 paidToBuyer);
    event SettlePutWithCash(uint256 index, uint256 tokenPrice, uint256 refund, uint256 eveCommission, uint256 paidToSeller);

    // emergency variable used to pause exchange activity
    bool public paused;

    // liquidity token to lend
    IERC20 public lendingToken;
    IERC20[] public lendingPaymentToken;
    mapping(address => bool) public lendingPaymentTokenAvailable;

    uint256 public minimumTimeToWithdraw = 2592000; // 1 month by default

    // keep track of the USD balance of each user
    mapping(address => uint256) public individualUSDBalance;

    // keep track of the last time a user deposited
    mapping(address => uint256) public depositTime;

    // total real balance in the contract deducting lendings
    uint256 public poolRealUSDBalance;

    // total (theoric) balance of the contract if no lending was made
    uint256 public poolUSDBalance;

    // contract's token balance
    mapping(address => uint256) public poolTokensBalance;

    event LiquidityAdded(address provider, uint256 amount);

    event Withdraw(address provider);

    constructor() Owner(msg.sender) {
        walletSet(msg.sender);
    }

    /**************************************************************************************************
     *
     *   M A N A G E R
     *
     **************************************************************************************************/

    /**
     * Set the admin wallet 
     * 
     * @param _wallet the new wallet
     *
     */
    function walletSet(address _wallet) public isOwner {
        require(_wallet != address(0), "OTC: cannot set the zero address");
        owner_wallet = _wallet;
    }

    /**
     * Set the admin commissions 
     * 
     * @param _commission_premium EVE commission to charge to reserve an option
     * @param _commission_sell EVE commission to charge to settlers on an option
     * @param _commission_lending EVE commission to charge for lending
     * @param _commission_pool Pool commission to charge for lending
     *
     */
    function commissionSet(uint16 _commission_premium, uint16 _commission_sell, uint16 _commission_lending, uint16 _commission_pool) public isOwner {

        // validate that commissions are not greater than 100%
        require(_commission_premium <= 10000, "Options premium commission cannot be greater than 100");
        require(_commission_sell <= 10000, "Options seller commission cannot be greater than 100");
        require(_commission_lending <= 10000, "Options lending commission cannot be greater than 100");
        require(_commission_pool <= 10000, "Options pool commission cannot be greater than 100");

        // update contract parameters
        commission_premium = _commission_premium;
        commission_sell = _commission_sell;
        commission_lending = _commission_lending;
        commission_pool = _commission_pool;

    }

    // set minimum profits
    function poolMinProfitSet(uint16 _pool_min_profit) public isOwner {
        require(pool_min_profit > 100, "Minimum value is 101 meaning 1% profits");
        pool_min_profit = _pool_min_profit;
    }

    // set minimum withdraw deposit time
    function poolTimeWithdrawSet(uint256 _time) public isOwner {
        minimumTimeToWithdraw = _time;
    }

    /**
     * Set the contract to use for staking
     * this will be used to determine discounts to apply
     */
    function stakingContractSet(IEVEOTCStakes _stakes) external isOwner {
        stakes = _stakes;
    }

    /**
     * Set the token to use for lending
     */
    function lendingTokenSet(IERC20 _lendingToken) external isOwner {
        lendingToken = _lendingToken;
    }

    /**
     * Set the contract to use for EVE Exchange
     * this will be used to find system tokens and prices
     */
    function eveExchangeContractSet(IEVEOTC _eveOtc) external isOwner {
        eveOtc = _eveOtc;
    }

    /**
     * Add / remove stable coins
     */

    function addStableCoin(IERC20 _coin) external isOwner {
        stable_coins.push(_coin);
        stableCoinsAvailable[address(_coin)] = true;
    }

    function removeStableCoin(uint256 _index) external isOwner {
        require(poolTokensBalance[address(stable_coins[_index])] == 0, "OTC: the token has balance in the contract, cannot be removed");
        stableCoinsAvailable[address(stable_coins[_index])] = false;
        stable_coins[_index] = stable_coins[stable_coins.length - 1];
        stable_coins.pop();
    }

    function stableCoinsLength() external view returns (uint256 len) {
        return stable_coins.length;
    }

    /**
     * Add / remove lending tokens
     */
    function addLendingPaymentToken(IERC20 _token) external isOwner {
        lendingPaymentToken.push(_token);
        lendingPaymentTokenAvailable[address(_token)] = true;
    }

    // Cannot remove token if it has balance
    function removeLendingPaymentToken(uint256 _index) external isOwner {
        require(poolTokensBalance[address(lendingPaymentToken[_index])] == 0, "OTC: the token has balance in the contract, cannot be removed");
        lendingPaymentTokenAvailable[address(lendingPaymentToken[_index])] = false;
        lendingPaymentToken[_index] = lendingPaymentToken[lendingPaymentToken.length - 1];
        lendingPaymentToken.pop();
    }

    function lendingPaymentTokenLength() external view returns (uint256 len) {
        return lendingPaymentToken.length;
    }

    /**************************************************************************************************
     *
     *   T R A D I N G
     *
     **************************************************************************************************/

    /**
     * Functions to get length of arrays
     */
    function options_length() external view returns(uint256 index) { return options.length; }

    /**
     *
     * Estimate put option cost
     *
     * @param _token: token on sale
     * @param _amount on sale (call) amount to buy (put)
     * @param _strike strike price on USD
     * @param _stableCoin IERC20 token
     * 
     */
    function estimatePutOption(IERC20 _token, uint256 _amount, uint256 _strike, IERC20 _stableCoin) view public returns (uint256 cost) {
        return _amount * _strike * 10**_stableCoin.decimals() / 10**_token.decimals() / 10**8;
    }

    /**
     *
     * Call option: Mike is sells an option for 1000 Matic at $1 strike / $100 Premium
     * Put option: Bob makes an options contract to buy 1000 Matic for $1. He locks $1000 USDC
     *
     * @param _call: is a call option? if false it is a put option
     * @param _token: token on sale
     * @param _premium the premium price in USD
     * @param _amount on sale (call) amount to buy (put)
     * @param _strike strike price on USD
     * @param _expiryTime expiry time in seconds
     * @param _stable stable coins token
     * 
     */
    function addOption(bool _call, IERC20 _token, uint256 _premium, uint256 _amount, uint256 _strike, uint256 _expiryTime, IERC20 _stable) external nonReentrant isNotPaused {

        require(_amount > 0, "OTC: Amount has to be greater than 0");
        require(_strike > 0, "OTC: Strike price has to be greater than 0");
        require(_premium > 0, "OTC: Premium price has to be greater than 0");
        require(_expiryTime > 0, "OTC: Expiry time has to be greater than 0");

        // Assumption: any token can be sold
        require(address(_token) != address(0), "OTC: Address cannot be the zero address");
        
        // emits an event
        emit NewOption(true, options.length, msg.sender, _token, _premium, _amount, _strike, block.timestamp, block.timestamp + _expiryTime);

        // add a call option
        if (_call) {

            // create the option
            options.push(Option(true, msg.sender, _token, _premium, _amount, _strike, block.timestamp, block.timestamp + _expiryTime, address(0), false, false, false));

            // lock the funds
            require(_token.transferFrom(msg.sender, address(this), _amount), "OTC: error transfering token funds");

        // add a put option
        } else {

            require(stableCoinsAvailable[address(_stable)], "OTC: stable coin not available");

            // set setlle token for the put option
            settleTokens[options.length] = _stable;

            // create the put option
            options.push(Option(false, address(0), _token, _premium, _amount, _strike, block.timestamp, block.timestamp + _expiryTime, msg.sender, false, false, false));

            // lock the funds
            require(_stable.transferFrom(msg.sender, address(this), estimatePutOption(_token, _amount, _strike, _stable)), "OTC: error transfering token funds");

        }

    }

    function canCancelOption(uint256 _index) external view returns (bool _can) {
        if (options[_index].canceled) return false;
        if (options[_index].premiumPaid && block.timestamp <= options[_index].expiry) return false;
        return true;
    }

    function cancelOption(uint256 _index) external nonReentrant {

        require((options[_index].call && options[_index].seller == msg.sender) || (!options[_index].call && options[_index].buyer == msg.sender), "OTC: caller is not authorized to cancel");
        require(!options[_index].canceled, "OTC: option is already canceled");
        require(!options[_index].premiumPaid || block.timestamp > options[_index].expiry, "OTC: the option has premium paid and has not expired");
        
        options[_index].canceled = true;

        emit CancelOption(_index);

        if (options[_index].call) {
            require(options[_index].token.transfer(msg.sender, options[_index].amount), "OTC: error transfering token funds");
        } else {
            require(settleTokens[_index].transfer(msg.sender, estimatePutOption(options[_index].token, options[_index].amount, options[_index].strike, settleTokens[_index])), "OTC: error transfering token funds");
        }

    }

    // calculate premium price
    function getPremiumPrice(uint256 _index, IERC20 _stable) public view returns(uint256 price) {
        uint256 totalTime = options[_index].expiry - options[_index].created;
        uint256 timePassed = block.timestamp - options[_index].created;
        uint256 thePrice = options[_index].premium - (options[_index].premium * timePassed / totalTime);
        return thePrice * 10**_stable.decimals() / 10**8;
    }

    // Bob buys the option for $100 - he pays the premium
    // Assumption: premium can be paid with any stable coin accepted in the system
    // Assumption: Stable coins are treated as if they have a 1:1 parity with the dollar price
    function payPremium(uint256 _index, IERC20 _stable) external nonReentrant isNotPaused {

        if (options[_index].call) {
            require(options[_index].seller != msg.sender, "OTC: the seller cannot pay the premium on a call option");
        }else {
            require(options[_index].buyer != msg.sender, "OTC: the buyer cannot pay the premium on a put option");
        }
        require(stableCoinsAvailable[address(_stable)], "OTC: stable coin not available");
        require(!options[_index].canceled, "OTC: option is canceled");
        require(!options[_index].premiumPaid, "OTC: the option is already paid");
        require(block.timestamp < options[_index].expiry, "OTC: the option has expired");

        // mark the premium paid
        options[_index].premiumPaid = true;

        uint256 premiumPrice = getPremiumPrice(_index, _stable);

        // calculates the commission at the moment of sale, to consider if the user has an active stake / discount
        (uint8 stake_discount_seller,) = stakes.getOptionDiscount(msg.sender);

        uint256 the_commission_premium = commission_premium;
        if (stake_discount_seller > 0) {
            the_commission_premium = the_commission_premium * (100 - stake_discount_seller) / 100;
        }

        // Assumption: if the seller has to pay a premium commission, this is discounted from the amount received
        uint256 premiumPriceCommission = premiumPrice * the_commission_premium / 10000;

        // reduce the commission
        premiumPrice -= premiumPriceCommission;

        // emit an event
        emit PayPremium(_index, msg.sender, premiumPrice, premiumPriceCommission);

        if (premiumPriceCommission > 0) {
            // transfer funds to seller
            require(_stable.transferFrom(msg.sender, owner_wallet, premiumPriceCommission), "OTC: error transfering token funds");
        }

        // transfer funds to owner of the option
        if (options[_index].call) {
            // if call option, owner is seller
            require(_stable.transferFrom(msg.sender, options[_index].seller, premiumPrice), "OTC: error transfering token funds");
            options[_index].buyer = msg.sender;
        } else {
            // if put option, owner is buyer
            require(_stable.transferFrom(msg.sender, options[_index].buyer, premiumPrice), "OTC: error transfering token funds");
            options[_index].seller = msg.sender;
        }

    }

    /**
     * Calculates the payment that the seller will receive and the commission the seller needs to pay to EVE
     * All payments are returned in an specific stable coin
     * @param _index: the option array index
     * @param _stableCoin: the ERC20 stable coint used for payments
     */
    function getSettleAmount(uint256 _index, IERC20 _stableCoin) public view returns(uint256 pay, uint256 commission) {

        /// Mike sells an option for 1000 Matic at $1 strike.
        // this is the amount of the option offer multiplied by the strike price and removing the selling token decimals, the 8 USD price decimals and adding the stable coin decimals
        uint256 _pay = options[_index].amount * options[_index].strike * 10 ** _stableCoin.decimals() / 100000000 / 10 ** options[_index].token.decimals();

        // calculates the commission at the moment of sale, to consider if the user has an active stake / discount
        (uint8 stake_discount_seller, ) = stakes.getOptionDiscount(options[_index].seller);

        uint256 the_commission_sell = commission_sell;
        if (stake_discount_seller > 0) {
            the_commission_sell = the_commission_sell * (100 - stake_discount_seller) / 100;
        }

        // Assumption: if the seller has to pay a commission, this is discounted from the amount received
        uint256 _payOwnerSelling = _pay * the_commission_sell / 10000;

        return (_pay - _payOwnerSelling, _payOwnerSelling);

    }

    function validateCall(uint256 _index) internal view {
        require(options[_index].call, "OTC: this is not a call option");
        require(!options[_index].canceled, "OTC: option is canceled");
        require(options[_index].premiumPaid, "OTC: premium is not paid");
        require(options[_index].buyer == msg.sender, "OTC: only the buyer can settle the call option");
        require(!options[_index].optionPaid, "OTC: option is already paid");
        require(block.timestamp < options[_index].expiry, "OTC: the option has expired");
    }

    function validatePut(uint256 _index) internal view {
        require(!options[_index].call, "OTC: this is not a put option");
        require(!options[_index].canceled, "OTC: option is canceled");
        require(options[_index].premiumPaid, "OTC: premium is not paid");
        require(options[_index].seller == msg.sender, "OTC: only the seller can settle the put option");
        require(!options[_index].optionPaid, "OTC: option is already paid");
        require(block.timestamp < options[_index].expiry, "OTC: the option has expired");
    }

    /**
     * Bob pays $1000 to Mike.
     * Mike gets $9995 - eve gets the $5 commission.
     * Bob gets 1000 Matic
     * 
     * Assumption: settling a Call Option can be done with any stable coin accepted in the system
     *
     * @param _index option to be settle
     * @param _stable stable coin to be use for settling
     */
    function settleCall(uint256 _index, IERC20 _stable) external nonReentrant isNotPaused {

        validateCall(_index);

        require(stableCoinsAvailable[address(_stable)], "OTC: stable coin not available");

        // emit event
        emit Settle(_index, address(_stable));

        // mark option as paid
        options[_index].optionPaid = true;

        // set setlle token
        settleTokens[_index] = _stable;

        (uint256 pay, uint256 payOwnerSelling) = getSettleAmount(_index, _stable);

        /// EVE gets the $5 commission.
        if (payOwnerSelling > 0) {
            require(_stable.transferFrom(msg.sender, owner_wallet, payOwnerSelling), "OTC: error transfering selling commission to owner");
        }

        /// Mike gets $9995        
        // pay the rest to the seller
        require(_stable.transferFrom(msg.sender, options[_index].seller, pay), "OTC: error transfering payment to seller");

        /// Bob gets 1000 Matic
        // transfer funds to buyer
        require(options[_index].token.transfer(msg.sender, options[_index].amount), "OTC: error transfering funds to buyer");

    }

    /**
     * 
     * Part 1
     * 
     * Bob is the maker
     * Mike is the taker
     * 
     * 1. Bob makes an options contract to buy 1000 Matic for $1. He locks $1000 USDC
     * 2. Mike buys the contract paying the premium $100 in USDC.
     * 3. Bob gets $99.50 eve gets .50 
     * 
     * Part 2
     * 
     * Matic is .80 and Mike wants to settle selling Matic for $1 to Bob.
     * Bob gets 1000 matic.
     * Mike gets $995, eve gets $5 - our commission. 
     * 
     */    
    function settlePut(uint256 _index) external nonReentrant isNotPaused {

        validatePut(_index);

        // emit event
        emit Settle(_index, address(settleTokens[_index]));

        // mark option as paid
        options[_index].optionPaid = true;

        /// Mike pays 1000 Matic to Bob.
        /// Bob gets 1000 Matic
        require(options[_index].token.transferFrom(msg.sender, options[_index].buyer, options[_index].amount), "OTC: error sending funds to buyer]");

        (uint256 pay, uint256 payOwnerSelling) = getSettleAmount(_index, settleTokens[_index]);

        /// Mike gets $995
        require(settleTokens[_index].transfer(msg.sender, pay), "OTC: error transfering funds to seller");

        /// EVE gets the $5 commission.
        if (payOwnerSelling > 0) {
            require(settleTokens[_index].transfer(owner_wallet, payOwnerSelling), "OTC: error transfering funds to admin");
        }

    }

    /**************************************************************************************************
     *
     *   L E N D I N G
     *
     **************************************************************************************************/

    /**
     * A Liquidity provider add funds to the contract and start participating in pool earnings
     */
    function addLiquidity(uint256 _amount) external nonReentrant isNotPaused {

        require(_amount > 0, "OTC: amount has to be greater than zero");

        emit LiquidityAdded(msg.sender, _amount);

        //Locks in the contract the amount (amount) of the token (lending token)
        lendingToken.transferFrom(msg.sender, address(this), _amount);

        // Save the amount
        individualUSDBalance[msg.sender] += _amount;
        depositTime[msg.sender] = block.timestamp;
        poolRealUSDBalance += _amount;
        poolUSDBalance += _amount;

    }

    /**
     * Liquidity provider withdrawal
     * Remove all funds from all tokens
     */
    function canWithdraw(address _add) external view returns (bool _can) {
        if (individualUSDBalance[_add] == 0) return false;
        if (block.timestamp - depositTime[_add] <= minimumTimeToWithdraw) return false;
        return true;
    }

    /**
     * Liquidity provider withdrawal
     * Remove all funds from all tokens
     */
    function withdraw() external nonReentrant isNotPaused {

        require(individualUSDBalance[msg.sender] > 0, "OTC: user has no balance");
        require(block.timestamp - depositTime[msg.sender] > minimumTimeToWithdraw, "OTC: user cannot withdraw yet");
        
        emit Withdraw(msg.sender);

        // The amount relative to the actual USD balance is transferred to the user
        uint256 _usdBalance = poolRealUSDBalance * individualUSDBalance[msg.sender] / poolUSDBalance;
        lendingToken.transfer(msg.sender, _usdBalance);

        // reduce this amount from the total balance
        poolRealUSDBalance -= _usdBalance;

        // The amount relative to the real balance of each token is transferred to the user
        for(uint256 i=0; i < lendingPaymentToken.length; i++) {
            uint256 _tokenBalance = poolTokensBalance[address(lendingPaymentToken[i])];
            if (_tokenBalance > 0) {
                uint256 _transferAmount = _tokenBalance * individualUSDBalance[msg.sender] / poolUSDBalance;
                lendingPaymentToken[i].transfer(msg.sender, _transferAmount);
                poolTokensBalance[address(lendingPaymentToken[i])] -= _transferAmount;
            }
        }

        // User data and global balance are updated
        poolUSDBalance -= individualUSDBalance[msg.sender];
        individualUSDBalance[msg.sender] = 0;

    }

    /**
     * Returns true if the pool can settle the call, false otherwise
     * @param _index option index
     */
    function canSettleCallWithLending(uint256 _index) external view returns (bool _can) {

        // is a call?
        if (!options[_index].call) return false;

        // is call option profitable?
        uint256 _coinPrice = eveOtc.getColdUSDPrice(address(options[_index].token));
        if (_coinPrice * 100 / options[_index].strike < pool_min_profit) return false;

        // the pool has enough money?
        (uint256 pay, uint256 payOwnerSelling) = getSettleAmount(_index, lendingToken);
        if (poolRealUSDBalance < pay + payOwnerSelling) return false;

        return true;

    }

    /**
     *
     * Mike sells a call option: 1000 Matic at 1$ strike price -> 1000 Matic locked
     * Bob buys the option for 100$ -> Mike gets 99.5$, EVE gets 0.5$
     * Matic goes 1.5$ per Matic, call option is profitable  (token price > strike price)
     * If loan:
     *     Pool pays Mike 1000$ (666 Matic) -> Mike gets 995$, EVE gets 5$
     *     Profit is: 334 Matic
     *     Pool gets the lended 666 Matic plus 10% commission: 699.4 Matic
     *     EVE gets 1% commission: 3.34 Matic
     *     Bob gets the rest: 1000 - 699.4 - 3.34 = 297.26 Matics
     *
     * @param _index option index
     *
     * Assumption: a minimum profit is required, 3% by default
     *
     */
    function settleCallWithLending(uint256 _index) external nonReentrant isNotPaused {

        validateCall(_index);

        require(lendingPaymentTokenAvailable[address(options[_index].token)], "OTC: the token is not available to cover lendings");

        // mark option as paid
        options[_index].optionPaid = true;

        // is call option profitable?
        // a call option is profitable if coin price > strike price
        // but we are checking a minimum threshold of profitability
        uint256 _coinPrice = eveOtc.getUSDPrice(address(options[_index].token));
        require(_coinPrice * 100 / options[_index].strike >= pool_min_profit, "OTC: call option is not profitable enough");

        // Pool pays Mike 1000$ (666 Matic) -> Mike gets 995$, EVE gets 5$
        (uint256 pay, uint256 payOwnerSelling) = getSettleAmount(_index, lendingToken);

        require(poolRealUSDBalance >= pay + payOwnerSelling, "OTC: not enough funds in the pool");

        /// EVE gets the $5 commission.
        if (payOwnerSelling > 0) {
            require(lendingToken.transfer(owner_wallet, payOwnerSelling), "OTC: error transfering selling commission to owner");
        }

        /// Mike gets $995        
        require(lendingToken.transfer(options[_index].seller, pay), "OTC: error transfering payment to seller");

        // discount the balance from the real USD balance of the lending contract
        poolRealUSDBalance -= pay + payOwnerSelling;

        // Profit is: 334 Matic
        // profit = amount * (price - strike) / price
        uint256 _profit = options[_index].amount * (_coinPrice - options[_index].strike) / _coinPrice;

        // Pool gets the lended 666 Matic plus 10% profit commission: 699.4 Matic
        uint256 _lent = options[_index].amount - _profit;
        uint256 _poolCommission = _profit * commission_pool / 10000;
        poolTokensBalance[address(options[_index].token)] += _lent + _poolCommission;

        // EVE gets 1% profit commission: 3.34 Matic
        uint256 _eveCommission = _profit * commission_lending / 10000;
        require(options[_index].token.transfer(owner_wallet, _eveCommission), "OTC: error transfering selling commission to owner");

        // Bob gets the rest: 1000 - 699.4 - 3.34 = 297.26 Matics
        uint256 _buyerPayment = options[_index].amount - _lent - _poolCommission - _eveCommission;
        require(options[_index].token.transfer(msg.sender, _buyerPayment), "OTC: error transfering funds to buyer");

        // emit event
        emit SettleWithLending(_index, true, _coinPrice, _profit, _lent + _poolCommission, _eveCommission, _buyerPayment);

    }

    function startSettlePut(uint256 _index) internal returns (uint256 coinPrice) {

        // emit event
        emit Settle(_index, address(settleTokens[_index]));

        // mark option as paid
        options[_index].optionPaid = true;

        // is put option profitable?
        // a put option is profitable if coin price < strike price
        // but we are checking a minimum threshold of profitability
        uint256 _coinPrice = eveOtc.getUSDPrice(address(options[_index].token));
        require(options[_index].strike * 100 / _coinPrice >= pool_min_profit, "OTC: put option is not profitable enough");

        return _coinPrice;

    }

    /**
     *
     * Returns the total deposited, the amount lent and the profit in the settle stable token decimals
     *
     * I sell 3000 Matic, strike: 0.5 -> the buyer deposited 1500$ USDC
     * 3000 * 0.5 = 1500
     * Matic baja a 0.3 -> 3000 matics, valued at 900
     * profit = amount * strike - amount * price = amount * (strike - price)
     * profit = 3000 * (0.5 - 0.3) = 3000 * 0.2 = 600
     * (Matic is 6 decimals), dollar is 8 decimals, matic is 9 decimals
     * profit = 3000000000 * (50000000 - 30000000) * 10**9 = 6×10**25 = 60000000000000000000000000 / 10**8 = 600000000000000000 / 10**6 = 600000000000 = 600 USDC
     *                                                     ^ usdc                                          ^ dolar                      ^ matic
     * Pool pays 3000 Matics and get 1500$, profit: 600
     * formula simplification
     * 
     * uint256 _totalDeposited = options[_index].amount * options[_index].strike                * 10**settleTokens[_index].decimals() / 100000000 / 10**options[_index].token.decimals();
     * uint256 _profit =         options[_index].amount * (options[_index].strike - _coinPrice) * 10**settleTokens[_index].decimals() / 100000000 / 10**options[_index].token.decimals();
     * uint256 _lent =           options[_index].amount * _coinPrice                            * 10**settleTokens[_index].decimals() / 100000000 / 10**options[_index].token.decimals();
     * uint256 _totalDeposited = options[_index].strike                * options[_index].amount * 10**settleTokens[_index].decimals() / 100000000 / 10**options[_index].token.decimals();
     * uint256 _profit =         (options[_index].strike - _coinPrice) * options[_index].amount * 10**settleTokens[_index].decimals() / 100000000 / 10**options[_index].token.decimals();
     * uint256 _lent =           _coinPrice                            * options[_index].amount * 10**settleTokens[_index].decimals() / 100000000 / 10**options[_index].token.decimals();
     * uint256 _totalDeposited = options[_index].strike                * options[_index].amount * 10**settleTokens[_index].decimals() / 100000000 / 10**options[_index].token.decimals();
     * uint256 _lent =           _coinPrice                            * options[_index].amount * 10**settleTokens[_index].decimals() / 100000000 / 10**options[_index].token.decimals();
     *
     */
     function calculatePutProfits(uint256 _index, uint256 _coinPrice) internal view returns (uint256 totalDeposited, uint256 lent, uint256 profit) {

        uint256 _multiplier = options[_index].amount * 10**settleTokens[_index].decimals();
        uint256 _divider = 100000000 * 10**options[_index].token.decimals();

        uint256 _totalDeposited = options[_index].strike * _multiplier / _divider;
        uint256 _lent =  _coinPrice * _multiplier / _divider;        
        uint256 _profit = _totalDeposited - _lent;

        return (_totalDeposited, _lent, _profit);

    }

    function canSettlePutWithLending(uint256 _index) external view returns (bool _can) {

        // is a put?
        if (options[_index].call) return false;

        // is put option profitable?
        // a put option is profitable if coin price < strike price
        // but we are checking a minimum threshold of profitability
        uint256 _coinPrice = eveOtc.getColdUSDPrice(address(options[_index].token));
        if (options[_index].strike * 100 / _coinPrice < pool_min_profit) return false;

        // a) Pool pays Bob 1000 Matic (valued at 800$)
        if (poolTokensBalance[address(options[_index].token)] < options[_index].amount) return false;

        return true;

    }

    /**
     *
     * Bob wants to buy 1000 Matics for 1$ each
     * Mike buys the option for 100$, Bob gets 99.5$, Eve gets 0.5$
     * Matic goes 0.8$ per Matic, so put option is profitable (token price < strike price)
     * Loan:
     *      a) Pool pays Bob 1000 Matic (valued at 800$)
     *      b) Profit is: 200$
     *      c) Pool gets the lended 800$ plus 10% commission: 20$ = 820$
     *      d) EVE gets 1% commission: 2$
     *      e) Mike gets the rest: 1000 - 820 - 2 = 178$
     *
     * @param _index option index
     *
     * Assumption: a minimum profit is required, 3% by default
     *
     */
    function settlePutWithLending(uint256 _index) external nonReentrant isNotPaused {

        validatePut(_index);

        require(lendingPaymentTokenAvailable[address(options[_index].token)], "OTC: the token is not available to cover lendings");

        // emit events, get price and validate profitability
        uint256 _coinPrice = startSettlePut(_index);

        // a) Pool pays Bob 1000 Matic (valued at 800$)
        require(poolTokensBalance[address(options[_index].token)] >= options[_index].amount, "OTC: not enough funds in the pool");
        require(options[_index].token.transfer(options[_index].buyer, options[_index].amount), "OTC: error sending funds to buyer]");

        // b) Profit is: 200$
        (uint256 _totalDeposited, uint256 _lent, uint256 _profit) = calculatePutProfits(_index, _coinPrice);

        // c) Pool gets the lended 800$ plus 10% commission: 20$ = 820$
        uint256 _poolCommission = _profit * commission_pool / 10000;
        poolTokensBalance[address(settleTokens[_index])] += _lent + _poolCommission;

        // d) EVE gets 1% commission: 2$
        uint256 _eveCommission = _profit * commission_lending / 10000;
        require(settleTokens[_index].transfer(owner_wallet, _eveCommission), "OTC: error transfering selling commission to owner");

        // e) Mike gets the rest: 1000 - 820 - 2 = 178$
        uint256 _sellerPayment = _totalDeposited - _lent - _poolCommission - _eveCommission;
        require(settleTokens[_index].transfer(msg.sender, _sellerPayment), "OTC: error transfering funds to seller");

        // emit event
        emit SettleWithLending(_index, false, _coinPrice, _profit, _lent + _poolCommission, _eveCommission, _sellerPayment);

    }

    /**************************************************************************************************
     *
     *   E M E R G E N C Y
     *
     **************************************************************************************************/

    /**
     * Pause smart contract trading activity
     */
    function pause() public isOwner {
        paused = true;
    }

    /**
     * Resume smart contract trading activity
     */
    function unpause() public isOwner {
        paused = false;
    }

    /**
     * modifier to check if the contract is paused
     */ 
    modifier isNotPaused() {
        require(!paused, "Smart Contract activity is paused");
        _;
    }

}