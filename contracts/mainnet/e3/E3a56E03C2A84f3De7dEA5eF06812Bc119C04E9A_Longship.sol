// SPDX-License-Identifier: Copyright 2022 Shipyard Software, Inc.
pragma solidity >=0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./libraries/SafeAggregatorInterface.sol";
import "./libraries/SimpleDatabase.sol";
import "./libraries/InvariantCalcs.sol";
import "./libraries/LongshipUtils.sol";


interface LongshipGlobal {
    function checkAddress(address toCheck) external view returns (bool);
    function getMinLongFeeBps() external view returns (uint256);
}

contract Longship is SimpleDatabase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeAggregatorInterface for address;
    using SafeCast for int256;
    using SafeCast for uint256;

    mapping(uint128 => uint256) bricks;
    mapping(uint256 => uint256) ints;
    mapping(uint256 => longStruct) public longs;
    mapping(uint256 => repoStruct) public repos;
    mapping(uint128 => uint128) next_brick_bases;
    mapping(uint256 => uint256) int_reckonings;

    struct longStruct {
        uint128 liq_price;
        uint128 leverage;
        uint128 collateral;
        uint64 expiry;
        address holder;
    }

    struct repoStruct{
        uint128 repo_amount;
        uint128 underlying_quantity;
        uint64 expiry;
        uint128 bankruptcy_payout;
        address holder;
    }

    address public immutable PARENT;
    address public immutable underlying;
    address private immutable oracle;
    // Oracle must have been updated at least 12 hours ago
    uint256 constant MINIMUM_ORACLE_TIME = (1 days)/2;
    uint256 private constant ORACLE_FAILURE_TIME = 1 weeks;
    bool internal TECH_FAILURE;
    uint256 internal TECH_FAILURE_TIMESTAMP;

    uint256 constant ONE_IN_DEFAULT_DECIMALS = 1e18;
    uint256 constant ONE_IN_BASIS_POINTS = 1e4;
    uint256 private immutable ONE_IN_TOKEN_DECIMALS;

    uint128 internal top_reckoning;
    uint128 internal top_slope;
    uint128 internal highest_base;
    uint128 internal lowest_brick_base;
    uint64 private immutable BRICK_SIZE;
    uint64 private constant TICKS_PER_BRICK = 128;
    uint32 private constant TICKS_PER_INT = 8;
    uint32 private constant INTS_PER_BRICK = 16;
    uint32 private constant BITS_PER_TICK = 32;
    uint32 private constant BRICK_SIZE_DENOM = 10;
    uint32 private constant CHOMP_DENOM = 10;
    uint32 private constant MINIMUM_LEVERAGE = 2;
    uint32 private constant MAX_LONG_QUAD_NODE = 10;
    uint256 private constant LONG_FEE_MULT = 5*(10**5);
    uint256 private constant ONE_IN_QUAD_DECIMALS = 10**16;
    uint256 private constant ONE_IN_DIMES = 10**7;
    uint256 private constant MAX_REPO_PAYOUT_NUM = 11*10**15;


    uint256 internal chomp_payouts;
    //mults and weights at 16 decimals (QUAD_DECIMALS)
    uint256[] internal mults = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    // [int(round(x)) for x in (1e16 / np.sqrt(np.pi)) * np.polynomial.hermite.hermgauss(16)[1]] 
    uint256[] private weights = [1497815, 1309473216, 153000321625, 5259849265739, 72669376011847, 472847523540140, 1583383727509496, 2865685212380120, 2865685212380120, 1583383727509496, 472847523540140, 72669376011847, 5259849265739, 153000321625, 1309473216, 1497815];
    // [int(round(x)) for x in 1e16*np.sqrt(2)*np.polynomial.hermite.hermgauss(16)[0]]
    int256[] private _base_mults = [-66308781983931296, -54722257059493440, -44929553025200120, -36008736241715488, -27602450476307016, -19519803457163336, -11638291005549650, -3867606045005574, 3867606045005574, 11638291005549650, 19519803457163336, 27602450476307016, 36008736241715488, 44929553025200120, 54722257059493440, 66308781983931296];

    uint256 private long_nonce = 1;
    uint256 private repo_nonce = 1;
    uint256 private repos_owed;
    uint32 private max_repo_quad_node;

    event LongOpened(uint256 indexed nonce, uint128 liq_price, uint128 leverage, uint128 collateral, uint64 expiry, address holder);
    event LongClosed(uint256 nonce);
    event LongChomped(uint256 nonce, uint80 roundId, address chomper);
    event LongLiquidatedBankruptcy(uint256 nonce, address liquidator);
    event RepoOpened(uint256 indexed nonce, uint128 repo_amount, uint128 underlying_quantity, uint64 expiry, uint128 bankruptcy_payout, address holder);
    event RepoRedeemed(uint256 nonce);
    event RepoChomped(uint256 nonce, address chomper);
    event DepositMade(uint256 underlying_added, uint256 tokens_minted, address depositor);
    event DepositWithdrawn(uint256 underlying_withdrawn, uint256 tokens_burned, address depositor);

    modifier onlyParent() {
        require(msg.sender==PARENT, "Not parent");
        _;
    }

    modifier requireTechFailure {
      require(TECH_FAILURE);
      _;
   }

    constructor(address theToken, address theOracle, address theParent, uint64 _BRICK_SIZE, uint256 volatility) {
        require(AggregatorV3Interface(theOracle).decimals()==8);

        underlying = theToken;
        uint256 _tokenDecimals = IERC20Metadata(theToken).decimals();
        ONE_IN_TOKEN_DECIMALS = 10**_tokenDecimals;

        oracle = theOracle;

        PARENT = theParent;    

        uint128 _init_base = (theOracle.safeUnsignedLatest(MINIMUM_ORACLE_TIME)/2).toUint128();
        BRICK_SIZE = _BRICK_SIZE;
        highest_base = _init_base;
        lowest_brick_base = _init_base;
        next_brick_bases[_init_base] = (_init_base*_BRICK_SIZE)/BRICK_SIZE_DENOM;
        
        setMultsForVolatility(volatility);
    }

    function setVolatility(uint256 newVolatility) external onlyParent {
        setMultsForVolatility(newVolatility);
    }

    function setMultsForVolatility(uint256 vol) internal {
        // vol is in basis points (4 decimals), base_mults are in 16. So this is 20 decimals, get back to 16
        int256 _vol = int256(vol);
        int256 _SIGNED_ONE = int256(ONE_IN_BASIS_POINTS);
        bool repo_node_set = false;
        for(uint32 i=0; i < _base_mults.length; i++){
            mults[i] = LongshipUtils.exp(_vol*_base_mults[i]);
            if (!repo_node_set && (mults[i] > MAX_REPO_PAYOUT_NUM)) {
                max_repo_quad_node = i;
                repo_node_set = true;
            }
        }
    }

    function safeEthSend(address recipient, uint256 howMuch) internal {
        (bool success, ) = payable(recipient).call{value: howMuch}("");
        require(success, "payable failed");
    }

    // Assumes you'd only attach value when the underlying is wrapped ETH
    function unifiedTransmit(uint256 howMuch) internal {
        require(LongshipGlobal(PARENT).checkAddress(msg.sender), "sanctioned");
        if(msg.value > 0){
            require(msg.value == howMuch);
            uint256 _bal = IERC20(underlying).balanceOf(address(this));
            safeEthSend(underlying, howMuch);
            require(IERC20(underlying).balanceOf(address(this))-_bal >= howMuch);
        } else {
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), howMuch);
        }
    }

    //gets current oracle price
    function currentOraclePrice() virtual public view returns (uint256) {
        return oracle.safeUnsignedLatest(MINIMUM_ORACLE_TIME);
    }

    //initiates technical failure flag if oracle has failed
    function checkOracle() public {
        if (!TECH_FAILURE) {
            if ((block.timestamp - oracle.latestTimestamp()) > ORACLE_FAILURE_TIME) {
                TECH_FAILURE = true;
                TECH_FAILURE_TIMESTAMP = block.timestamp;
            }
        }
    }

    function tokensFromDollars(uint256 dollar_amt) internal view returns(uint256){
        return (ONE_IN_TOKEN_DECIMALS*dollar_amt)/currentOraclePrice();
    }

    function setBrick(uint128 reckoning_amt, uint128 reckoning_slope, uint128 base) internal {
        uint256 brick = uint256(reckoning_amt);
        brick |= uint256(reckoning_slope)<<128;
        bricks[base] = brick;
    }

    function addToBrick(uint128 _amt, uint128 _slope, uint128 base) internal {
        uint256 brick = bricks[base];
        setBrick(uint128(brick) + _amt, uint128(brick>>128) + _slope, base);  
    }

    function subtractFromBrick(uint128 _amt, uint128 _slope, uint128 base) internal {
        uint256 brick = bricks[base];
        setBrick(uint128(brick) - _amt, uint128(brick>>128) - _slope, base);  
    }

    function setInt(uint128 brick_base, uint128 int_index, uint256 int_value) internal {
        uint256 int_key = uint256(brick_base);
        int_key |= uint256(int_index)<<128;
        ints[int_key] = int_value;
    }

    //adds to a specific tick using bitmask
    function modTick(uint128 brick_base, uint128 tick_index, uint32 tick_value, bool plus_minus_flag) internal {
        uint128 int_index = tick_index/TICKS_PER_INT;
        uint128 tick_in_int_index = tick_index % TICKS_PER_INT;
        uint256 int_key = uint256(brick_base);
        int_key |= uint256(int_index)<<128;
        uint256 _int = ints[int_key];
        uint32 tick = uint32(_int>>(tick_in_int_index*BITS_PER_TICK));
        uint32 tick_updated;
        if (plus_minus_flag){
            tick_updated = tick + tick_value;
        }
        else {
            tick_updated = tick - tick_value;
        }
        uint256 _int_updated = _int & (~ (uint256(2**32 - 1)<<(tick_in_int_index*BITS_PER_TICK)));
        _int_updated |= (uint256(tick_updated)<<tick_in_int_index*BITS_PER_TICK);
        ints[int_key] = _int_updated;
    }

    //gets an int as an array of its 32 bit values
    function getSplitInt(uint128 brick_base, uint128 int_index) internal view returns(uint32[] memory){
        uint256 int_key = uint256(brick_base);
        int_key |= uint256(int_index)<<128;
        uint256 _int = ints[int_key];
        uint32[] memory split_int = new uint32[](TICKS_PER_INT);
        for (uint i = 0; i < TICKS_PER_INT; i++) {
            split_int[i] = uint32(_int>>(i*BITS_PER_TICK));
        }
        return split_int;
    }

    function getReckoningOfInt(uint128 brick_base, uint128 int_index) internal view returns(uint128, uint128){
        uint256 int_key = uint256(brick_base);
        int_key |= uint256(int_index)<<128;
        uint256 reckoning_int_raw = int_reckonings[int_key];
        uint128 reckoning_amt = uint128(reckoning_int_raw);
        uint128 reckoning_slope = uint128(reckoning_int_raw>>128);
        return(reckoning_amt, reckoning_slope);
    }

    function setReckoningOfInt(uint128 brick_base, uint128 int_index, uint128 reckoning_amt, uint128 reckoning_slope) internal {
        uint256 int_key = uint256(brick_base);
        int_key |= uint256(int_index)<<128;
        uint256 int_reckoning_raw = uint256(reckoning_amt);
        int_reckoning_raw |= uint256(reckoning_slope)<<128;
        int_reckonings[int_key] = int_reckoning_raw;
    }

    //adds a brick to the top of the stack
    function addBrickTop() internal {
        uint128 highest_base_uncovered = next_brick_bases[highest_base];
        uint128 new_brick_base = highest_base_uncovered;
        uint128 new_brick_reckoning = top_reckoning;
        uint128 new_brick_slope = top_slope;
        setBrick(new_brick_reckoning, new_brick_slope, new_brick_base);
        top_reckoning += top_slope*(new_brick_base - highest_base_uncovered);
        highest_base_uncovered = (new_brick_base*BRICK_SIZE)/BRICK_SIZE_DENOM;
        highest_base = new_brick_base;
        next_brick_bases[new_brick_base] = highest_base_uncovered;
    }

    //adds a brick to the bottom of the stack
    function addBrickBottom() internal {
        uint128 new_brick_base = (lowest_brick_base*BRICK_SIZE_DENOM)/BRICK_SIZE;
        setBrick(0, 0, new_brick_base);
        next_brick_bases[new_brick_base] = lowest_brick_base;
        lowest_brick_base = new_brick_base;
    }

    //adds a long to the payout fields/data structures and resolves its liq price to the next highest tick
    function addLong(uint128 liq_price, uint128 total_margin, uint256 chomp_payout) internal returns(uint128 resolved_liq_price){
        uint128 highest_base_uncovered = next_brick_bases[highest_base];

        if (liq_price >= highest_base_uncovered){
            while(liq_price >= highest_base_uncovered){
                addBrickTop();
                highest_base_uncovered = next_brick_bases[highest_base];
            }
        }

        if (liq_price < lowest_brick_base){
            while(liq_price < lowest_brick_base){
                addBrickBottom();
            }
        }

        uint128 target_base = lowest_brick_base;
        uint128 current_base = next_brick_bases[target_base]; 

        while(liq_price >= current_base){
            target_base = current_base; 
            current_base = next_brick_bases[target_base];
        }

        uint128 tick_size = (current_base - target_base)/TICKS_PER_BRICK;
        uint128 int_index;
        {
            uint128 tick_index;
            if (((liq_price - target_base) % tick_size) != 0){
                tick_index = 1 + (liq_price - target_base)/tick_size;
            } else {
                tick_index = (liq_price - target_base)/tick_size;
            }
            if (tick_index == (TICKS_PER_BRICK)){
                return addLong(current_base, total_margin, chomp_payout);
            }
            

            modTick(target_base, tick_index, marginScaleToUSD(total_margin, target_base), true);

            int_index = tick_index/TICKS_PER_INT + 1;
            resolved_liq_price = tick_index*tick_size + target_base;
        }
        while(int_index < (INTS_PER_BRICK)){
            updateIntReckoningUp(target_base, resolved_liq_price, int_index, tick_size, total_margin);
            int_index += 1;
        }

        uint256 _marginal_amt;
        while(current_base < highest_base_uncovered){
            //(Price - Price)*(Token)/(ONE_IN_TOKEN_DECIMALS) = usd units
            _marginal_amt = (uint256(current_base - resolved_liq_price)*uint256(total_margin))/ONE_IN_TOKEN_DECIMALS;
            uint128 marginal_amt = SafeCast.toUint128(_marginal_amt);
            uint128 marginal_slope = total_margin;
            addToBrick(marginal_amt, marginal_slope, current_base);
            current_base = next_brick_bases[current_base];
        }

        top_slope += total_margin;
        _marginal_amt = (uint256(highest_base_uncovered - resolved_liq_price)*uint256(total_margin))/ONE_IN_TOKEN_DECIMALS;
        top_reckoning += SafeCast.toUint128(_marginal_amt);
        chomp_payouts += chomp_payout;

        return resolved_liq_price;
    }

    //remove a long from data structures, also prunes blocks at the end if they are now empty
    function removeLong(uint128 liq_price, uint128 total_margin, uint256 chomp_payout) internal {
        chomp_payouts -= chomp_payout;
        uint128 current_base = lowest_brick_base;
        uint128 target_base = current_base; 
        uint128 prev_base;
        while(liq_price >= current_base){
            prev_base = target_base;
            target_base = current_base;  
            current_base = next_brick_bases[target_base];
        }

        uint128 tick_size = (current_base - target_base)/TICKS_PER_BRICK;

        modTick(target_base, (liq_price - target_base)/tick_size, marginScaleToUSD(total_margin, target_base), false);

        uint128 int_index = ((liq_price - target_base)/tick_size)/TICKS_PER_INT + 1;
        while(int_index < (INTS_PER_BRICK)){
            updateIntReckoningDown(target_base, liq_price, int_index, tick_size, total_margin);
            int_index += 1;
        }

        uint128 highest_base_uncovered = next_brick_bases[highest_base];
        uint256 _marginal_amt;
        while(current_base < highest_base_uncovered){
            _marginal_amt = (uint256(current_base - liq_price)*uint256(total_margin))/ONE_IN_TOKEN_DECIMALS;
            uint128 marginal_amt = SafeCast.toUint128(_marginal_amt);
            uint128 marginal_slope = total_margin;
            subtractFromBrick(marginal_amt, marginal_slope, current_base);
            current_base = next_brick_bases[current_base];
        }

        top_slope -= total_margin;
        _marginal_amt = (uint256(highest_base_uncovered - liq_price)*uint256(total_margin))/ONE_IN_TOKEN_DECIMALS;
        top_reckoning -= SafeCast.toUint128(_marginal_amt);


        //pruning bricks
        uint256 this_brick = bricks[target_base];
        uint128 this_reckoning_slope = uint128(this_brick>>128);

        if (! ((target_base == lowest_brick_base) && (target_base == highest_base))){
            if  (this_reckoning_slope == top_reckoning){
                highest_base = prev_base;
            }
            else {
            {
                uint256 next_brick = bricks[next_brick_bases[target_base]];
                uint128 next_reckoning_slope = uint128(next_brick>>128);
                if (0 == next_reckoning_slope){
                    lowest_brick_base = next_brick_bases[target_base];
                }
            }
            }
        }
    }

    //adds to an int reckoning
    function updateIntReckoningUp(uint128 target_base, uint128 liq_price, uint128 int_index, uint128 tick_size, uint128 total_margin) internal {
        (uint128 int_reckoning_amt, uint128 int_reckoning_slope) = getReckoningOfInt(target_base, int_index);
        int_reckoning_slope += total_margin;
        uint128 this_int_price = tick_size*TICKS_PER_INT*int_index + target_base;
        uint256 marginal_int_reckoning_amt = (uint256(this_int_price-liq_price)*uint256(total_margin))/(ONE_IN_TOKEN_DECIMALS);
        int_reckoning_amt += SafeCast.toUint128(marginal_int_reckoning_amt);
        setReckoningOfInt(target_base, int_index, int_reckoning_amt, int_reckoning_slope);
    }

    //subtracts from an int reckoning
    function updateIntReckoningDown(uint128 target_base, uint128 liq_price, uint128 int_index, uint128 tick_size, uint128 total_margin) internal {
        (uint128 int_reckoning_amt, uint128 int_reckoning_slope) = getReckoningOfInt(target_base, int_index);
        int_reckoning_slope -= total_margin;
        uint128 this_int_price = tick_size*TICKS_PER_INT*int_index + target_base;
        uint256 marginal_int_reckoning_amt = (uint256(this_int_price-liq_price)*uint256(total_margin))/(ONE_IN_TOKEN_DECIMALS);
        int_reckoning_amt -= SafeCast.toUint128(marginal_int_reckoning_amt);
        setReckoningOfInt(target_base, int_index, int_reckoning_amt, int_reckoning_slope);
    }

    //gets the payouts owed to long holders or chompers at an array of prices (must be in ascending order)
    function getPayouts(uint256[] memory prices) public view returns (uint256[] memory){
        uint128 current_base = lowest_brick_base;
        uint128 highest_base_uncovered = next_brick_bases[highest_base];
        uint256[] memory payouts = new uint256[](prices.length);
        uint32 i = 0;
        while((i < prices.length) && (prices[i] < current_base)){
            //Chomp payouts in token units, so (Token*Price)/(ONE_IN_TOKEN_DECIMALS) = price
            payouts[i] += (chomp_payouts*prices[i])/ONE_IN_TOKEN_DECIMALS;
            i += 1;
        }
        uint128 target_base = current_base;
        while((current_base <= highest_base_uncovered) && (i < prices.length)){ 
            current_base = next_brick_bases[target_base];
            uint256 this_brick = bricks[target_base];
            uint128 brick_reckoning_amt = uint128(this_brick);
            uint128 brick_reckoning_slope = uint128(this_brick>>128);
            while(prices[i]<current_base){
                uint256 _payout = getPayoutFromInt(prices[i], target_base, (current_base - target_base)/TICKS_PER_BRICK);
                //(Price - Price)*Token/ONE_IN_TOKEN_DECIMALS + USD + (token*price)/ONE_IN_TOKEN_DECIMALS = USD value
                payouts[i] = _payout + (prices[i] - uint256(target_base))*uint256(brick_reckoning_slope)/ONE_IN_TOKEN_DECIMALS 
                + brick_reckoning_amt + (chomp_payouts*prices[i])/ONE_IN_TOKEN_DECIMALS;
                i = i+1;
                if (i >= prices.length){
                    break;
                }
            }

            if(current_base == highest_base_uncovered){
                break;
            }
            target_base = current_base;
            current_base = next_brick_bases[target_base];
        }

        while(i<prices.length){
            payouts[i] = (prices[i] - highest_base_uncovered)*top_slope/ONE_IN_TOKEN_DECIMALS + top_reckoning + (chomp_payouts*prices[i])/ONE_IN_TOKEN_DECIMALS;
            i = i+1;
        }
        
        //emit Payouts(payouts);
        return payouts;
    }

    //gets the payout of longs contained in the block which encompasses the price queried
    function getPayoutFromInt(uint256 _price, uint128 target_base, uint128 tick_size) public view returns(uint256){  
        uint256 tick_index = (_price - target_base)/uint256(tick_size);
        uint128 int_index = uint128(tick_index/TICKS_PER_INT);
        (uint128 int_reckoning_amt, uint128 int_reckoning_slope) = getReckoningOfInt(target_base, int_index);
        uint32[] memory split_int = getSplitInt(target_base, int_index);
        uint256 curr_price = int_index*TICKS_PER_INT*tick_size + uint256(target_base);
        //USD + (Price - Price)*Token/ONE_IN_TOKEN_DECIMALS = USD value
        uint256 _payout = uint256(int_reckoning_amt) + (uint256(int_reckoning_slope)*(_price - curr_price))/ONE_IN_TOKEN_DECIMALS;
        uint32 j = 0;
        while(curr_price < _price){
            //(Price - Price)*Token/ONE_IN_TOKEN_DECIMALS = USD value
            _payout += ((_price - curr_price)*(marginUnscaleTwoFiftySix(split_int[j], target_base)))/ONE_IN_TOKEN_DECIMALS;
            j = j+1;
            curr_price += tick_size;
        }
        //emit Payoutsmall(_payout);
        return _payout;
    }
    
    //scales the margin of a long from token units to dimes
    function marginScaleToUSD(uint128 underlying_margin, uint128 brick_base) internal view returns(uint32){
        uint256 mult = (uint256(underlying_margin)*brick_base)/(ONE_IN_TOKEN_DECIMALS*ONE_IN_DIMES);
        uint32 mult_small = SafeCast.toUint32(mult);
        return mult_small;
    }

    //converts back from dimes to token units
    function marginUnscale(uint32 scaled_margin, uint128 brick_base) internal view returns(uint128){
        uint256 _scaled_margin = uint256(scaled_margin);
        uint256 mult = (_scaled_margin*ONE_IN_TOKEN_DECIMALS*ONE_IN_DIMES)/(brick_base);
        return SafeCast.toUint128(mult);
    }

    //converts baack from dimes to a uint256
    function marginUnscaleTwoFiftySix(uint32 scaled_margin, uint128 brick_base) internal view returns(uint256){
        uint256 _scaled_margin = uint256(scaled_margin);
        uint256 mult = (_scaled_margin*ONE_IN_TOKEN_DECIMALS*ONE_IN_DIMES)/(brick_base);
        return mult;
    }

    //gets lp tokesn owed from a deposit
    function lpTokensForDeposit(uint256 underlyingToAdd) public view returns (uint256 tokensToMint) {
        uint256 currentLPTokens = totalSupply();
        if(currentLPTokens==0){
            // Converts from TOKEN_DECIMALS to DEFAULT_DECIMALS (we want our token to be 18 decimals)
            tokensToMint = underlyingToAdd*ONE_IN_DEFAULT_DECIMALS/ONE_IN_TOKEN_DECIMALS;
            return tokensToMint;
        } else {
            InvariantCalcs.invariantReturnStruct memory irs = InvariantCalcs.getInvariantsLP(underlyingToAdd, 0, getQuadraturePrices(), getPayouts(getQuadraturePrices()), weights, IERC20(underlying).balanceOf(address(this)), repos_owed, ONE_IN_TOKEN_DECIMALS);
            uint256 currentInvariant = irs.invariant_before;
            uint256 invariantWithLPAdded = irs.invariant_after;
            tokensToMint = (((invariantWithLPAdded - currentInvariant)*ONE_IN_DEFAULT_DECIMALS*currentLPTokens)/currentInvariant)/ONE_IN_DEFAULT_DECIMALS;
        }
    }

    //gets fraction of invariant removed from an lp withdrawal
    function invariantFractionFromSendBack(uint256 underlyingToSendBack) public view returns (uint256 fractionOfInvariantRemoved) {
        InvariantCalcs.invariantReturnStruct memory irs = InvariantCalcs.getInvariantsLP(0, underlyingToSendBack, getQuadraturePrices(), getPayouts(getQuadraturePrices()), weights, IERC20(underlying).balanceOf(address(this)), repos_owed, ONE_IN_TOKEN_DECIMALS);
        (uint256 currentInvariant, uint256 invariantWithUnderlyingRemoved) = (irs.invariant_before, irs.invariant_after);

        fractionOfInvariantRemoved = (currentInvariant - invariantWithUnderlyingRemoved)*ONE_IN_DEFAULT_DECIMALS/currentInvariant;
    }

    //public function to add liquidity
    function makeLPDeposit(uint256 underlyingToAdd, address holder) external nonReentrant payable {
        uint256 tokensToMint = lpTokensForDeposit(underlyingToAdd);
        unifiedTransmit(underlyingToAdd);
        _mint(holder, tokensToMint);
        emit DepositMade(underlyingToAdd, tokensToMint, holder);
    }

    //public function to remove liquidity
    function removeLPDeposit(uint256 underlyingToSendBack) external nonReentrant {
        uint256 fractionOfInvariantRemoved = invariantFractionFromSendBack(underlyingToSendBack);
        // fraction is in DEFAULT_DECIMALS
        uint256 correspondingTokenToBurn= (fractionOfInvariantRemoved*totalSupply())/ONE_IN_DEFAULT_DECIMALS;
        // Reverts if not enough token is held
        _burn(msg.sender, correspondingTokenToBurn);
        IERC20(underlying).safeTransfer(msg.sender, underlyingToSendBack);
        emit DepositWithdrawn(underlyingToSendBack, correspondingTokenToBurn, msg.sender);
    } 


    //opens a repo
    function openRepo(uint256 quantity, uint256 price, address holder) external payable nonReentrant returns (uint256) {
        unifiedTransmit(quantity);
        InvariantCalcs.invariantReturnStruct memory irs = InvariantCalcs.getInvariantsRepo(quantity, price, getPayouts(getQuadraturePrices()), weights, getQuadraturePrices(), IERC20(underlying).balanceOf(address(this)), repos_owed, ONE_IN_TOKEN_DECIMALS);
        if (irs.bankrupt_bool == false){
            if(irs.invariant_after > irs.invariant_before){
                return addRepo(quantity, price, holder);
            }
            else {
                revert("No invariant increase");
            }
        } else {
            if ((irs.first_node > max_repo_quad_node) &&(price < (currentOraclePrice()*MAX_REPO_PAYOUT_NUM)/ONE_IN_QUAD_DECIMALS)){
                return addRepo(quantity, price, holder);
            }
            else {
                revert("Bankrupt");
            }
        }
    }

    //adds a repo to internal data structures
    function addRepo(uint256 underlying_quantity, uint256 price, address holder) internal returns (uint256){
        repos_owed += price*underlying_quantity/ONE_IN_TOKEN_DECIMALS;
        uint64 expiry = uint64(block.timestamp) + 1 days;
        repoStruct memory repo = repoStruct(SafeCast.toUint128(price*underlying_quantity/ONE_IN_TOKEN_DECIMALS), SafeCast.toUint128(underlying_quantity), expiry, SafeCast.toUint128((price*underlying_quantity)/ONE_IN_TOKEN_DECIMALS), holder);
        repos[repo_nonce] = repo;
        emit RepoOpened(repo_nonce, repo.repo_amount, repo.underlying_quantity, repo.expiry, repo.bankruptcy_payout, repo.holder);
        repo_nonce += 1;
        return repo_nonce-1;
    }

    //redeems a repo, only callable by repo creator
    function redeemRepo(uint256 nonce) external nonReentrant {
        repoStruct storage repo = repos[nonce];
        require(msg.sender == repo.holder);
        require(repo.expiry != 0);
        InvariantCalcs.invariantReturnStruct memory irs = InvariantCalcs.getInvariant(getQuadraturePrices(), getPayouts(getQuadraturePrices()), weights, IERC20(underlying).balanceOf(address(this)), repos_owed, ONE_IN_TOKEN_DECIMALS);
        if((irs.bankrupt_bool == true) && (irs.first_node==0)){
            revert("Short bankrupt");
        }
        if (block.timestamp > repo.expiry){
            repos_owed -= repo.repo_amount;
            IERC20(underlying).safeTransfer(msg.sender, tokensFromDollars(repo.repo_amount));
            delete(repos[nonce]);
            emit RepoRedeemed(nonce);
        }
        else {
            revert("Not mature");
        }
    }

    //get quadrature prices from current oracle price
    function getQuadraturePrices() public view returns (uint256[] memory){
        uint256[] memory prices = new uint256[](mults.length);
        uint256 _oraclePrice = currentOraclePrice();
        for (uint i = 0; i < mults.length; i++) {
            prices[i] = (mults[i]*_oraclePrice)/ONE_IN_QUAD_DECIMALS;
        }
        return prices;
    }

    //open a long
    function openLong(uint128 liq_price, uint128 leverage, uint128 collateral, address holder) external payable nonReentrant returns (uint256){
        uint128 total_margin = (leverage)*collateral;
        InvariantCalcs.invLongStruct memory requested_long = InvariantCalcs.invLongStruct(liq_price, leverage, collateral, 0, holder);
        InvariantCalcs.invariantReturnStruct memory irs = InvariantCalcs.getInvariantsLong(LongshipGlobal(PARENT).getMinLongFeeBps().toUint128(), getQuadraturePrices(), requested_long, getPayouts(getQuadraturePrices()), weights, IERC20(underlying).balanceOf(address(this)), repos_owed, ONE_IN_TOKEN_DECIMALS);
        if (liq_price > currentOraclePrice()*mults[MAX_LONG_QUAD_NODE]/ONE_IN_QUAD_DECIMALS){
            revert("Liquidation price too high");
        }
        if (leverage < MINIMUM_LEVERAGE) {
            revert("Leverage too low");
        }
        if((irs.bankrupt_bool==true)&&(irs.first_node==(mults.length-1))){
            revert("Long bankrupt");
        }
        if (irs.invariant_after > irs.invariant_before){
            unifiedTransmit(collateral);
            uint128 resolved_liq_price = addLong(liq_price, total_margin, collateral/CHOMP_DENOM);
            uint64 expiry = uint64(block.timestamp) + 1 days;
            longStruct memory long = longStruct(resolved_liq_price, leverage, collateral, expiry, holder);
            longs[long_nonce] = long;
            emit LongOpened(long_nonce, resolved_liq_price, leverage, collateral, expiry, holder);
            long_nonce += 1;
            return long_nonce-1;
        } else {
            revert("No invariant increase");
        }
    }

    //close a long, only callabe by long creator
    function closeLong(uint256 nonce) external nonReentrant {
        longStruct storage long = longs[nonce];
        require(msg.sender==long.holder);
        if (long.expiry == 0){
            revert("Long does not exist");
        }
        if (block.timestamp > long.expiry){
            uint128 liq_price = long.liq_price;
            uint128 chomp_payout = long.collateral/CHOMP_DENOM;
            uint128 total_margin = (long.leverage*long.collateral) - chomp_payout;
            uint256 payout = InvariantCalcs.payoutFromLong(liq_price, total_margin, chomp_payout, currentOraclePrice(), ONE_IN_TOKEN_DECIMALS);
            removeLong(liq_price, total_margin, chomp_payout);
            emit LongClosed(nonce);
            delete(longs[nonce]);
            IERC20(underlying).safeTransfer(msg.sender, tokensFromDollars(payout));
        } else {
            revert("Not mature");
        }
    }

    //chomp long if below liq price, callable by anyone
    function chompLong(uint256 nonce, uint80 roundId) external nonReentrant {
        longStruct storage long = longs[nonce];
        if (long.expiry == 0){
            revert("Long does not exist");
        }
        (uint256 thePrice, uint256 theTimestamp) = oracle.safeUnsignedAndTimestampAtRound(roundId);
        if (theTimestamp >= long.expiry){
            uint128 liq_price = long.liq_price;
            uint128 chomp_payout = long.collateral/CHOMP_DENOM;
            uint128 total_margin = (long.leverage*long.collateral) - chomp_payout;
            if (thePrice <= uint256(liq_price)){
                IERC20(underlying).safeTransfer(msg.sender, chomp_payout);
                removeLong(liq_price, total_margin, chomp_payout);
                delete(longs[nonce]);
                emit LongChomped(nonce, roundId, msg.sender);
            }
        } else {
            revert("Not mature");
        }
    }


    //close long at minimum leverage, callable only when system is long bankrupt
    function bankruptcyLiquidateLong(uint256 nonce) external nonReentrant {
        InvariantCalcs.invariantReturnStruct memory irs = InvariantCalcs.getInvariantReverse(getQuadraturePrices(), getPayouts(getQuadraturePrices()), weights, IERC20(underlying).balanceOf(address(this)), repos_owed, ONE_IN_TOKEN_DECIMALS);
        if(!((irs.bankrupt_bool==true)&&(irs.first_node==(mults.length-1)))){
            revert("not long bankrupt");
        }
        longStruct storage long = longs[nonce];
        uint128 chomp_payout = long.collateral/CHOMP_DENOM;
        uint128 total_minimum_margin = SafeCast.toUint128(MINIMUM_LEVERAGE*long.collateral - chomp_payout);
        uint128 original_total_margin = SafeCast.toUint128(long.leverage*long.collateral - chomp_payout);
        uint256 payout = InvariantCalcs.payoutFromLong(long.liq_price, total_minimum_margin, chomp_payout, currentOraclePrice(), ONE_IN_TOKEN_DECIMALS);
        IERC20(underlying).safeTransfer(msg.sender, tokensFromDollars(payout));
        removeLong(long.liq_price, original_total_margin, chomp_payout);
        delete(longs[nonce]);
        emit LongLiquidatedBankruptcy(nonce, msg.sender);
    }
    

    //chomp repo when system is short bankrupt
    function bankruptcyChompRepo(uint256 nonce) external nonReentrant {
        InvariantCalcs.invariantReturnStruct memory irs = InvariantCalcs.getInvariant(getQuadraturePrices(), getPayouts(getQuadraturePrices()), weights, IERC20(underlying).balanceOf(address(this)), repos_owed, ONE_IN_TOKEN_DECIMALS);
        if((irs.bankrupt_bool==true) && (irs.first_node == 0)){
            repoStruct storage repo = repos[nonce];
            if (repo.expiry == 0){
                revert("Repo does not exist");
            }
            uint256 to_transfer = repo.bankruptcy_payout;
            IERC20(underlying).safeTransfer(repo.holder, tokensFromDollars(to_transfer));
            repos_owed -= repo.repo_amount;
            delete(repos[nonce]);
            emit RepoChomped(nonce, msg.sender);
        }
        else {
            revert("Not bankrupt");
        }
    }

    //get underlying back in case of technical failure
    function redeemUnderlyingLongTechFailure(uint256 nonce) external nonReentrant requireTechFailure{
        longStruct storage long = longs[nonce];
        IERC20(underlying).safeTransfer(long.holder, long.collateral);
        delete(longs[nonce]);
    }

    //get input of repo back in case of technical failure
    function redeemUnderlyingRepoTechFailure(uint256 nonce) external nonReentrant requireTechFailure {
        repoStruct storage repo = repos[nonce];
        IERC20(underlying).safeTransfer(repo.holder, repo.underlying_quantity);
        delete(repos[nonce]);
    }

    //get pro rata share of lp in case of technical failure
    function redeemLPTechFailure(uint256 tokenToBurn) external nonReentrant requireTechFailure {
        if (block.timestamp > (TECH_FAILURE_TIMESTAMP + 1 weeks)){
            uint256 underlyingToSendBack = IERC20(underlying).balanceOf(address(this))*tokenToBurn/totalSupply();
            _burn(msg.sender, tokenToBurn);
            IERC20(underlying).safeTransfer(msg.sender, underlyingToSendBack);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: Copyright 2022 Shipyard Software, Inc.
pragma solidity >=0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library SafeAggregatorInterface {
    using SafeCast for int256;

    // Returns the latest price from the oracle as a uint256, reverting if invalid or older than minimumTime
    function safeUnsignedLatest(address oracle, uint256 minimumTime) public view returns (uint256) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = AggregatorV3Interface(oracle).latestRoundData();
        require((roundId==answeredInRound) && (updatedAt+minimumTime > block.timestamp), "Oracle out of date");
        return answer.toUint256();
    }

    // Returns the uint256 price at a certain round from the oracle, and the timestamp of that round
    // Reverts if invalid
    function safeUnsignedAndTimestampAtRound(address oracle, uint80 roundId) public view returns (uint256,uint256) {
        (uint80 theRoundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = AggregatorV3Interface(oracle).getRoundData(roundId);
        require(theRoundId==answeredInRound, "Oracle reading invalid");
        return (answer.toUint256(), updatedAt);
    }

    function latestTimestamp(address oracle) internal view returns (uint256) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = AggregatorV3Interface(oracle).latestRoundData();
        return updatedAt;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;


/*
	Simple token database for storing mints, burns, and a total balance.

	"ERC20 without transfer" derived from OpenZeppelin ERC20 library
*/
contract SimpleDatabase {
	mapping(address => uint256) private _balances;
    	mapping(address => uint64) internal _lastDeposits;

	uint256 private _totalSupply;
	uint64 private MINIMUM_LOCKUP_PERIOD = 1 days;

	function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        _lastDeposits[account] = uint64(block.timestamp);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from the zero address");
        require(_lastDeposits[account] <= (block.timestamp - MINIMUM_LOCKUP_PERIOD), "Lock up period still in effect");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
    }

}

// SPDX-License-Identifier: Copyright 2022 Shipyard Software, Inc.
pragma solidity >=0.8.4;

library InvariantCalcs {

    uint256 constant ONE_IN_QUAD_DECIMALS = 10**16;
    uint128 constant CHOMP_DENOM = 10;
    uint128 constant LONG_FEE_DENOM = 10**8;
    uint256 constant USD_UTILITY_WEIGHT = 25;
    uint256 constant UTILITY_WEIGHT_DENOM = 100;

    struct invariantReturnStruct{
        bool bankrupt_bool;
        uint32 first_node; 
        uint256 invariant_before; 
        uint256 invariant_after;
    }

    struct invLongStruct {
        uint128 liq_price;
        uint128 leverage;
        uint128 collateral;
        uint64 expiry;
        address holder;
    }

    //gets the invariant given price and state data
    function getInvariant(uint256[] memory prices, uint256[] memory payouts, uint256[] memory weights, uint256 _balance, uint256 repos_owed, uint256 ONE_IN_TOKEN_DECIMALS) external pure returns (invariantReturnStruct memory) {
        uint256[] memory wealth = new uint256[](prices.length);

        for (uint32 i = 0; i < prices.length; i++) {
            uint256 pos_wealth = _balance*prices[i]/ONE_IN_TOKEN_DECIMALS;
            uint256 neg_wealth = payouts[i] + repos_owed;
            if (neg_wealth > pos_wealth){
                return invariantReturnStruct(true, i, 0, 0);
            }
            wealth[i] = pos_wealth - neg_wealth;
        }

        return invariantReturnStruct(false, 0, invariantFromWealth(wealth, weights, prices), 0);
    }

    //gets the invariant given price and state data starting from the highest quadrature node
    function getInvariantReverse(uint256[] memory prices, uint256[] memory payouts, uint256[] memory weights, uint256 _balance, uint256 repos_owed, uint256 ONE_IN_TOKEN_DECIMALS) public pure returns (invariantReturnStruct memory) {
        uint256[] memory wealth = new uint256[](prices.length);

        for (uint32 i = uint32(prices.length); i > 0; i--) {
            uint256 pos_wealth = _balance*prices[i-1]/ONE_IN_TOKEN_DECIMALS;
            uint256 neg_wealth = payouts[i-1] + repos_owed;
            if (neg_wealth > pos_wealth){
                return invariantReturnStruct(true, i-1, 0, 0);
            }
            wealth[i] = pos_wealth - neg_wealth;
        }

        return invariantReturnStruct(false, 0, invariantFromWealth(wealth, weights, prices), 0);
    }

    //version of getInvariant for evaluating potential liquidity provision
    function getInvariantsLP(uint256 lpToAdd, uint256 lpToRemove, uint256[] memory prices, uint256[] memory payouts, uint256[] memory weights, uint256 _balance, uint256 repos_owed, uint256 ONE_IN_TOKEN_DECIMALS) external pure returns (invariantReturnStruct memory) {
        uint256[] memory wealth = new uint256[](prices.length);

        uint256[] memory counterfactual_wealth = new uint256[](prices.length);
        

        for (uint32 i = 0; i < prices.length; i++) {
            {
                uint256 pos_wealth = _balance*prices[i]/ONE_IN_TOKEN_DECIMALS;
                uint256 neg_wealth = payouts[i] + repos_owed;
                if (neg_wealth > pos_wealth){
                    return invariantReturnStruct(true, i, 0, 0);
                }
                wealth[i] = pos_wealth - neg_wealth;
            }
            uint256 plusWealth = lpToAdd*prices[i]/ONE_IN_TOKEN_DECIMALS;
            uint256 minusWealth = lpToRemove*prices[i]/ONE_IN_TOKEN_DECIMALS;
            if(minusWealth > (wealth[i] + plusWealth)){
                revert("Withdrawal makes bankrupt");
            }

            counterfactual_wealth[i] = wealth[i] + plusWealth - minusWealth;
        }

        return invariantReturnStruct(false, 0, invariantFromWealth(wealth, weights, prices), invariantFromWealth(counterfactual_wealth, weights, prices));
    }

    //payout from a long at given price
    function payoutFromLong(uint128 liq_price, uint128 total_margin, uint128 chomp_payout, uint256 price, uint256 ONE_IN_TOKEN_DECIMALS) public pure returns(uint256){
        uint256 payout = 0;
        payout += chomp_payout*price/ONE_IN_TOKEN_DECIMALS;
        if (uint256(liq_price) < price){
            payout += ((price - uint256(liq_price))*total_margin)/(ONE_IN_TOKEN_DECIMALS);
        }
        return payout;
    }

    //version of getInvariant for evaluating potential long opening
    function getInvariantsLong(uint128 longFeeBps, uint256[] memory prices, invLongStruct memory requested_long, uint256[] memory payouts, uint256[] memory weights, uint256 _balance, uint256 repos_owed, uint256 ONE_IN_TOKEN_DECIMALS) public pure
    returns (invariantReturnStruct memory) {
        uint256[] memory wealth = new uint256[](prices.length);
        uint256[] memory counterfactual_wealth = new uint256[](prices.length);

        requested_long.liq_price = (requested_long.liq_price*(LONG_FEE_DENOM - longFeeBps))/(LONG_FEE_DENOM);

        for (uint32 i = uint32(prices.length); i > 0; i--) {
            {
                uint256 pos_wealth = _balance*prices[i-1]/ONE_IN_TOKEN_DECIMALS;
                uint256 neg_wealth = payouts[i-1] + repos_owed;
                if (neg_wealth > pos_wealth){
                    return invariantReturnStruct(true, i-1, 0, 0);
                }
                wealth[i-1] = pos_wealth - neg_wealth;
            }
            
            uint256 _long_payout = payoutFromLong(requested_long.liq_price, (requested_long.leverage*requested_long.collateral - requested_long.collateral/CHOMP_DENOM), requested_long.collateral/CHOMP_DENOM, prices[i-1], ONE_IN_TOKEN_DECIMALS);
            if(_long_payout > (wealth[i-1] + requested_long.collateral*prices[i-1]/ONE_IN_TOKEN_DECIMALS)){
                revert("Long makes bankrupt");
            }
            counterfactual_wealth[i-1] = wealth[i-1] + requested_long.collateral*prices[i-1]/ONE_IN_TOKEN_DECIMALS - _long_payout;
        }

        return invariantReturnStruct(false, 0, invariantFromWealth(wealth, weights, prices), invariantFromWealth(counterfactual_wealth, weights, prices));
    }

    //version of getInvariant for evaluating potential repo trade
    function getInvariantsRepo(uint256 quantity, uint256 repo_price, uint256[] memory payouts, uint256[] memory weights, uint256[] memory prices, uint256 _balance, uint256 repos_owed, uint256 ONE_IN_TOKEN_DECIMALS) external pure 
    returns (invariantReturnStruct memory) {
        uint256[] memory wealth = new uint256[](prices.length);


        uint256[] memory counterfactual_wealth = new uint256[](prices.length);
        uint256 repo_payout = quantity*repo_price/ONE_IN_TOKEN_DECIMALS;
        
        for (uint32 i = 0; i < prices.length; i++) {
            {
            uint256 pos_wealth = _balance*prices[i]/ONE_IN_TOKEN_DECIMALS;
            uint256 neg_wealth = payouts[i] + repos_owed;
            if (neg_wealth > pos_wealth){
                return invariantReturnStruct(true, i, 0, 0);
            }
            wealth[i] = pos_wealth - neg_wealth;
            }
            if(repo_payout > (wealth[i] + quantity*prices[i]/ONE_IN_TOKEN_DECIMALS)){
                revert("Proposed repo would make system bankrupt at one or more quadrature nodes");
            }

            counterfactual_wealth[i] = wealth[i] + quantity*prices[i]/ONE_IN_TOKEN_DECIMALS - repo_payout;
        }

        return invariantReturnStruct(false, 0, invariantFromWealth(wealth, weights, prices), invariantFromWealth(counterfactual_wealth, weights, prices));
    }

    function invariantFromWealth(uint256[] memory wealth, uint256[] memory weights, uint256[] memory prices) internal pure returns (uint256) {
        //assume wealth at 8 decimal point resolution (chainlink)
        //reciprocal calc done with 1 = 1*10^28, so 20 additional OOM
        uint256 _one = 1*10**28;
        uint256 usd_utility;
        uint256 underlying_utility;
        uint256 oracle_price = (prices[7] + prices[8])/2;

        for (uint i = 0; i < wealth.length; i++) {
            //weights at 16 decimals, will be resolved when invariant is set below
            uint256 the_weight_times_one = (weights[i]*_one);
            usd_utility += the_weight_times_one/wealth[i];
            underlying_utility += ((the_weight_times_one*prices[i])/wealth[i])/oracle_price;
        }
        
        return ((_one*ONE_IN_QUAD_DECIMALS*USD_UTILITY_WEIGHT)/usd_utility)/UTILITY_WEIGHT_DENOM +
        ((_one*ONE_IN_QUAD_DECIMALS*(UTILITY_WEIGHT_DENOM - USD_UTILITY_WEIGHT))/underlying_utility)/UTILITY_WEIGHT_DENOM;
    }

}

// SPDX-License-Identifier: Copyright 2022 Shipyard Software, Inc.
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@prb/math/contracts/PRBMathSD59x18.sol";

library LongshipUtils {
    using SafeCast for int256;

    function exp(int256 x) external pure returns (uint256) {
        int256 x_formatted = x/(10**2);
        return (PRBMathSD59x18.exp(x_formatted)/(10**2)).toUint256();
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x == MIN_SD59x18) {
                revert PRBMathSD59x18__AbsInputTooSmall();
            }
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            int256 sum = (x >> 1) + (y >> 1);
            if (sum < 0) {
                // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
                // right rounds down to infinity.
                assembly {
                    result := add(sum, and(or(x, y), 1))
                }
            } else {
                // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
                // remainder gets truncated twice.
                result = sum + (x & y & 1);
            }
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

            unchecked {
                // Convert x to the 192.64-bit fixed-point format.
                uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = int256(PRBMath.exp2(x192x64));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < MIN_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntUnderflow(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathSD59x18__GmOverflow(x, y);
            }

            // The product cannot be negative.
            if (xy < 0) {
                revert PRBMathSD59x18__GmNegativeProduct(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMath.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
            if (rAbs > uint256(MAX_SD59x18)) {
                revert PRBMathSD59x18__MulOverflow(rAbs);
            }

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < 0) {
                revert PRBMathSD59x18__SqrtNegativeInput(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMath.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}