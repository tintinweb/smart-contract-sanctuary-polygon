// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Mining.sol";

contract BuyerStaking is DoublePoolNestChef {
    bytes32 internal constant _limit_           = 'limit';
    bytes32 internal constant _DOTC_            = 'DOTC';
    bytes32 internal constant _punishTo_        = 'punishTo';
    bytes32 internal constant _expiry_          = 'expiry';

    mapping(address=>uint) stakeTimes;

    function __BuyerStaking_init(address _governor, address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr, address _stakingPool2, address _rewardsToken2,address _rewardsToken3, uint limit_, address DOTC_, address punishTo_, uint expiry_) public initializer {
        super.__DoublePoolNestChef_init(_governor, _rewardsDistribution, _rewardsToken, _stakingToken,  _ecoAddr, _stakingPool2, _rewardsToken2, _rewardsToken3);
        __BuyerStaking_init_unchained(limit_, DOTC_, punishTo_, expiry_);
	}

    function __BuyerStaking_init_unchained(uint limit_, address DOTC_, address punishTo_, uint expiry_) internal governance initializer{
	    config[_limit_]     = limit_;
        config[_DOTC_]      = uint(DOTC_);
        config[_punishTo_]  = uint(punishTo_);
        config[_expiry_]    = expiry_;//now.add(expiry_);
	}
    
    function limit() virtual public view returns(uint) {
        return config[_limit_];
    }
    
    function enough(address buyer) virtual external view returns(bool) {
        return _balances[buyer] >= limit();
    }

    function punish(address buyer,uint vol) virtual external updateReward(buyer) updateReward(address(config[_punishTo_])) updateReward2(buyer) updateReward2(address(config[_punishTo_])) {
        require(msg.sender == address(config[_DOTC_]), 'only DOTC');
        address punishTo = address(config[_punishTo_]);
        uint amt = _balances[buyer];
        require(amt>=vol,"stake must GT punish vol");
        _balances[buyer] = amt.sub(vol);
        _balances[punishTo] = _balances[punishTo].add(vol);

        emit Punish(buyer, vol);
    }
    event Punish(address buyer, uint amt);

    function stake(uint amount) virtual override public {
        amount;
        require(_balances[msg.sender] < config[_limit_], 'already');
        uint realAmount = config[_limit_].sub(_balances[msg.sender]);
        stakeTimes[msg.sender] = now;
        super.stake(realAmount);
    }

    function withdrawEnable(address account) public view returns (bool){
        return ((now > stakeTimes[account].add(config[_expiry_]))&&(IDOTC(address(config[_DOTC_])).biddingN(account) == 0)&&(_balances[account]>0));
    }

    function withdraw(uint amount) virtual override public {
        amount;
        require(now > stakeTimes[msg.sender].add(config[_expiry_]), 'only expired');
        require(IDOTC(address(config[_DOTC_])).biddingN(msg.sender) == 0, 'bidding');
        uint realAmount = _balances[msg.sender];
        require(realAmount > 0,"No Stake to withdraw");
        super.withdraw(realAmount);
    }
    uint256[49] private ______gap;
}

interface IDOTC {
    function biddingN(address buyer) external view returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

struct SMake {
    address maker;
    bool isBid;
    address asset;
    uint256 volume;
    bytes32 currency;
    uint256 price;
    uint256 payType;
    uint256 pending;
    uint256 remain;
    uint256 minVol;
    uint256 maxVol;
    string link;
    uint256 adPex;
}

struct STake {
    uint256 makeID;
    address taker;
    uint256 vol;
    Status status;
    uint256 expiry;
    string link;
    uint256 realPrice;
    address recommender;
}

enum Status {
    None,
    Paid,
    Cancel,
    Done,
    Appeal,
    Buyer,
    Seller,
    Vault,
    MerchantOk,
    MerchantAppeal,
    MerchantAppealDone,
    ClaimTradingMargin
}

struct AppealInfo {
    uint256 takeID;
    address appeal;
    address arbiter;
    Status winner; //0 Status.None  Status.Buyer Status.seller  assetTo
    //Status assetTo;  //buyer seller
    Status appealFeeTo; //vault  buyer seller
    //address buyStakeTo;  //LP punish always to vault
    //buystaking  lp punish to vault
    Status punishSide; //0 Status.None  Status.Buyer Status.seller
    uint256 punishVol;
    Status punishTo; //other side or vault
    bool isDeliver;
}

struct ArbiterPara {
    uint256 takeID;
    Status winner;
    //Status assetTo;
    Status appealFeeTo;
    Status punishSide;
    uint256 punishVol;
    Status punishTo; //other side or vault
}

struct SMakeEx {
    bool isPrivate;
    string memo;
    uint256 tradingMargin;
    uint256 priceType; //0:fix  1:float plus 2:float %
    int256 floatVal; //plus or %
}

struct TakePara {
    uint256 makeID;
    uint256 volume;
    string link;
    uint256 price;
    address recommender;
}

contract DOTC is Configurable {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 internal constant _expiry_ = "expiry";
    //bytes32 internal constant _feeTo_       = "feeTo";
    bytes32 internal constant _feeToken_ = "feeToken";
    bytes32 internal constant _feeVolume_ = "feeVolume";
    bytes32 internal constant _feeRate_ = "feeRate";
    bytes32 internal constant _feeRatio1_ = "feeRatio1";
    bytes32 internal constant _feeBuf_ = "feeBuf";
    bytes32 internal constant _lastUpdateBuf_ = "lastUpdateBuf";
    bytes32 internal constant _spanBuf_ = "spanBuf";
    bytes32 internal constant _spanLock_ = "spanLock";
    bytes32 internal constant _rewardOfSpan_ = "rewardOfSpan";
    bytes32 internal constant _rewardRatioMaker_ = "rewardRatioMaker";
    bytes32 internal constant _rewardToken_ = "rewardToken";
    bytes32 internal constant _rewards_ = "rewards";
    bytes32 internal constant _locked_ = "locked";
    bytes32 internal constant _lockEnd_ = "lockEnd";
    /*  bytes32 internal constant _rebaseTime_  = "rebaseTime";
    bytes32 internal constant _rebasePeriod_= "rebasePeriod";
    bytes32 internal constant _factorPrice20_   = "factorPrice20";
    bytes32 internal constant _lpTknMaxRatio_   = "lpTknMaxRatio";
    bytes32 internal constant _lpCurMaxRatio_   = "lpCurMaxRatio";*/
    bytes32 internal constant _vault_ = "vault";
    bytes32 internal constant _pairTokenA_ = "pairTokenA";
    bytes32 internal constant _swapFactory_ = "swapFactory";
    bytes32 internal constant _swapRouter_ = "swapRouter";
    bytes32 internal constant _mine_ = "mine";
    bytes32 internal constant _assetList_ = "assetList";
    bytes32 internal constant _assetFreeLimit_ = "assetFreeLimit";
    bytes32 internal constant _usd_ = "usd";
    bytes32 internal constant _bank_ = "bank";
    bytes32 internal constant _merchantPool_ = "merchantPool";
    bytes32 internal constant _tradingPool_ = "tradingPool";
    bytes32 internal constant _preDoneExpiry_ = "preDoneExpiry"; //7days
    bytes32 internal constant _priceAndRate_ = "priceAndRate";
    // bytes32 internal constant _babtoken_ = "babtoken";

    address public staking;
    address[] public arbiters;
    mapping(address => bool) public isArbiter;
    mapping(address => uint256) public biddingN;

    mapping(uint256 => SMake) public makes;
    mapping(uint256 => STake) public takes;
    uint256 public makesN;
    uint256 public takesN;

    mapping(uint256 => address) public appealAddress; //takeID=> appeal address  //obs    new  appealInfos
    mapping(uint256 => bool) public makePrivate; //makeID=> public or private; //obs    new makeExs

    uint256 private _entered;
    modifier nonReentrant() {
        require(_entered == 0, "reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }

    mapping(address => string) public links; //tg link
    mapping(uint256 => AppealInfo) public appealInfos; //takeID=> AppealInfo

    mapping(uint256 => SMakeEx) public makeExs; //makeID=>SMakeEx

    bytes32[] public customFiatFeeKeys;
    mapping(bytes32 => uint256) public fiatFeeMap; //currency=>feeRate
    bytes32 internal constant _claimFor_ = "claimFor";

    function __DOTC_init(
        address governor_,
        address staking_,
        address feeTo_,
        address feeToken_,
        uint256 feeVolume_
    ) public initializer {
        __Governable_init_unchained(governor_);
        __DOTC_init_unchained(staking_, feeTo_, feeToken_, feeVolume_);
    }

    function __DOTC_init_unchained(
        address staking_,
        address vault_,
        address feeToken_,
        uint256 feeVolume_
    ) internal governance initializer {
        staking = staking_;
        config[_expiry_] = 30 minutes;
        config[_vault_] = uint256(vault_);
        config[_feeToken_] = uint256(feeToken_);
        config[_feeVolume_] = feeVolume_;

        __DOTC_init_reward();
    }

    function __DOTC_init_reward() public governance {
        config[_feeRate_] = 0.01e18; //  1%
        config[_feeRatio1_] = 1e18; //0.10e18;        // 10% 100%
        config[_feeBuf_] = 1_000_000e18;
        config[_lastUpdateBuf_] = now;
        config[_spanBuf_] = 5 days;
        config[_spanLock_] = 5 days;
        config[_rewardOfSpan_] = 0; //1_000_000e18;
        config[_rewardRatioMaker_] = 0.25e18; // 25%
        config[_rewardToken_] = uint256(
            0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7
        ); // tPear
        config[_pairTokenA_] = uint256(
            0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7
        ); // BUSD
        config[_swapFactory_] = uint256(
            0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
        ); // PancakeFactory V2
        config[_swapRouter_] = uint256(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        ); // PancakeRouter V2
        config[_mine_] = uint256(0x7b32Fb7cf54d5BEe923Af8d9175a2cecC1059269);
        _setConfig(_assetList_, 0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7, 1); // BUSD
        _setConfig(_assetList_, 0xc2132D05D31c914a87C6611C10748AEb04B58e8F, 1); // USDT
        _setConfig(_assetList_, 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, 1); // USDC
        __DOTC_init_reward2();
    }

    function __DOTC_init_reward2() public governance {
        //  _setConfig(_assetFreeLimit_, 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56, 1e18);    // BUSD //test 1
        //  _setConfig(_assetFreeLimit_, 0x55d398326f99059fF775485246999027B3197955, 1e18);    // USDT
        //  _setConfig(_assetFreeLimit_, 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d, 1e18);    // USDC
        config[_usd_] = uint256(0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7); // BUSD
        config[_rewardToken_] = uint256(
            0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7
        ); // pear

        /*config[_rebaseTime_      ] = now.add(0 days).add(8 hours).sub(now % 8 hours);
        config[_rebasePeriod_    ] = 8 hours;
        config[_factorPrice20_   ] = 1.1e18;           // price20 = price1 * 1.1
        config[_lpTknMaxRatio_   ] = 0.10e18;        // 10%
        config[_lpCurMaxRatio_   ] = 0.50e18;        // 50% */
        config[_pairTokenA_] = uint256(
            0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3
        ); // WBNB
        //config[_feeTo_] = uint(address(this));
        (, uint256 p2) = priceEth();
        p2 = p2.div(2); //50% off
        config[_feeBuf_] = config[_rewardOfSpan_].mul(p2).div(1e18);
    }

    /* function migrate(address vault_) external governance {
        config[_vault_] = uint(vault_);
        __DOTC_init_reward2();
    }*/

    function setBiddingN_(address account, uint256 biddingN_)
        external
        governance
    {
        biddingN[account] = biddingN_;
    }

    function setVault_(address vault_) public governance {
        config[_vault_] = uint256(vault_);
    }

    function setCustomFiatFee(
        bytes32[] memory fiatList,
        uint256[] memory feeList
    ) external governance {
        customFiatFeeKeys = fiatList;

        for (uint256 i = 0; i < fiatList.length; i++) {
            fiatFeeMap[fiatList[i]] = feeList[i];
        }
    }

    function isCustomFiat(bytes32 currency) public returns (bool include) {
        for (uint256 i = 0; i < customFiatFeeKeys.length; i++) {
            if (currency == customFiatFeeKeys[i]) {
                include = true;
                break;
            }
        }
    }

    function setArbiters_(
        address[] calldata arbiters_,
        string[] calldata links_
    ) external governance {
        for (uint256 i = 0; i < arbiters.length; i++)
            isArbiter[arbiters[i]] = false;

        arbiters = arbiters_;

        for (uint256 i = 0; i < arbiters.length; i++) {
            isArbiter[arbiters[i]] = true;
            links[arbiters[i]] = links_[i];
        }

        emit SetArbiters(arbiters_);
    }

    event SetArbiters(address[] arbiters_);

    function make(
        SMake memory make_,
        SMakeEx memory makeEx_ /*bool isPrivate*/
    ) external virtual nonReentrant returns (uint256 makeID) {
        require(make_.volume > 0, "volume should > 0");
        require(make_.minVol <= make_.maxVol, "minVol must <= maxVol");
        require(make_.maxVol <= make_.volume, "maxVol must <= volume");
        if (makeEx_.tradingMargin > 0) {
            require(
                IMerchantStakePool(address(config[_merchantPool_])).isMerchant(
                    msg.sender
                ),
                "must merchant"
            );
        } else if (
            make_.volume > getConfigA(_assetFreeLimit_, make_.asset) &&
            !IMerchantStakePool(address(config[_merchantPool_])).isMerchant(
                msg.sender
            )
        ) {
            require(
                IStaking(staking).enough(msg.sender),
                "make ad GT Limit,must stake"
            );
        }
        if (make_.isBid) {
            //require(staking == address(0) || IStaking(staking).enough(msg.sender));
            biddingN[msg.sender]++;
        } else
            IERC20(make_.asset).safeTransferFrom(
                msg.sender,
                address(this),
                make_.volume
            );
        if (make_.adPex > 0)
            IERC20(address(config[_rewardToken_])).safeTransferFrom(
                msg.sender,
                address(config[_vault_]),
                make_.adPex
            );
        makeID = makesN;
        make_.maker = msg.sender;
        make_.pending = 0;
        make_.remain = make_.volume;
        makes[makeID] = make_; //SMake(msg.sender, isBid, asset, volume, currency, price,payType, 0, volume,minVol,maxVol,link,adPex,isPrivate);
        //makePrivate[makeID] = isPrivate;
        makeExs[makeID] = makeEx_;
        makesN++;
        emit Make(
            makeID,
            msg.sender,
            make_.isBid,
            make_.asset,
            make_,
            makeEx_.isPrivate
        );
        emit MakeEx(makeID, makeEx_);
    }

    event Make(
        uint256 indexed makeID,
        address indexed maker,
        bool isBid,
        address indexed asset,
        SMake smake,
        bool isPrivate
    );
    event MakeEx(uint256 indexed makeID, SMakeEx makeExs);

    function cancelMake(uint256 makeID)
        external
        virtual
        nonReentrant
        returns (uint256 vol)
    {
        require(makes[makeID].maker != address(0), "Nonexistent make order");
        require(makes[makeID].maker == msg.sender, "only maker");
        require(makes[makeID].remain > 0, "make.remain should > 0");
        //require(config[_disableCancle_] == 0, 'disable cancle');

        vol = makes[makeID].remain;
        if (!makes[makeID].isBid)
            IERC20(makes[makeID].asset).safeTransfer(msg.sender, vol);
        else {
            if (makes[makeID].pending == 0)
                biddingN[msg.sender] = biddingN[msg.sender].sub(1);
        }
        makes[makeID].remain = 0;
        emit CancelMake(makeID, msg.sender, makes[makeID].asset, vol);
    }

    event CancelMake(
        uint256 indexed makeID,
        address indexed maker,
        address indexed asset,
        uint256 vol
    );

    function reprice(uint256 makeID, uint256 newPrice)
        external
        virtual
        returns (uint256 vol, uint256 newMakeID)
    {
        require(makes[makeID].maker != address(0), "Nonexistent make order");
        require(makes[makeID].maker == msg.sender, "only maker");
        require(makes[makeID].remain > 0, "make.remain should > 0");

        vol = makes[makeID].remain;
        //bool makePri = makePrivate[makeID];
        newMakeID = makesN;
        SMake memory newMake;
        newMake = makes[makeID];
        newMake.volume = vol;
        newMake.price = newPrice;
        newMake.pending = 0;
        newMake.remain = vol;
        makes[newMakeID] = newMake;
        //makePrivate[newMakeID] = makePri;
        makeExs[newMakeID] = makeExs[makeID];
        makesN++;
        makes[makeID].remain = 0;
        if (makes[makeID].isBid && makes[makeID].pending > 0) {
            biddingN[msg.sender] = biddingN[msg.sender].add(1);
        }
        emit CancelMake(makeID, msg.sender, makes[makeID].asset, vol);
        emit Make(
            newMakeID,
            msg.sender,
            makes[newMakeID].isBid,
            makes[newMakeID].asset,
            makes[newMakeID],
            makeExs[newMakeID].isPrivate
        );
        emit Reprice(
            makeID,
            newMakeID,
            msg.sender,
            newMake,
            makeExs[newMakeID].isPrivate
        );
    }

    event Reprice(
        uint256 indexed makeID,
        uint256 indexed newMakeID,
        address indexed maker,
        SMake smake,
        bool makePri
    );

    function take(
        uint256 makeID,
        uint256 volume,
        string memory link,
        uint256 price,
        address recommender
    ) external virtual nonReentrant returns (uint256 takeID, uint256 vol) {
        //(takeID,vol) = ArbitrateLib.takeLib(makes,makeExs,takes,config,biddingN,makeID,volume,link,price,recommender);
        (takeID, vol) = ArbitrateLib.takeLib(
            makes,
            makeExs,
            takes,
            config,
            biddingN,
            TakePara(makeID, volume, link, price, recommender)
        );

        takesN++;

        /*require(makes[makeID].maker != address(0), 'Nonexistent make order');
        require(makes[makeID].remain > 0, 'make.remain should > 0');
        require(makes[makeID].minVol <= volume , 'volume must > minVol');
        require(makes[makeID].maxVol >= volume, 'volume must < maxVol');
        if (makeExs[makeID].tradingMargin>0){//config[_tradingPool_]
            IERC20(address(config[_feeToken_])).safeTransferFrom(msg.sender, address(this), makeExs[makeID].tradingMargin);
            if(IERC20(address(config[_feeToken_])).allowance(address(this),address(config[_tradingPool_]))<makeExs[makeID].tradingMargin)
                IERC20(address(config[_feeToken_])).approve(address(config[_tradingPool_]),uint(-1));
            ITradingStakePool(address(config[_tradingPool_])).stake(msg.sender,makeExs[makeID].tradingMargin);
        }else if (volume > getConfigA(_assetFreeLimit_,makes[makeID].asset))
            require(IStaking(staking).enough(msg.sender),"GT Limit,must stake");
        vol = volume;
        if(vol > makes[makeID].remain)
            vol = makes[makeID].remain;
        if(!makes[makeID].isBid) {
            //require(staking == address(0) || IStaking(staking).enough(msg.sender));
            biddingN[msg.sender]++;
        } else
            IERC20(makes[makeID].asset).safeTransferFrom(msg.sender, address(this), vol);
        makes[makeID].remain = makes[makeID].remain.sub(vol);
        makes[makeID].pending = makes[makeID].pending.add(vol);
        
        uint realPrice;
        uint priceType = makeExs[makeID].priceType;
        if(priceType!=0){
            (uint price1,uint8 decimals,uint rate) = IPriceAndRate(address(config[_priceAndRate_])).getPriceAndRate(makes[makeID].asset,makes[makeID].currency);
            require(price1>0,"No the asset");
            require(rate>0,"No the currency");
            if (priceType ==1)
                realPrice = price1.mul(rate).div(uint(decimals)).add(makeExs[makeID].floatVal);//1170e18 *6.71e18
            else if(priceType ==2)
                realPrice = price1.mul(rate).div(uint(decimals)).mul(1e18+makeExs[makeID].floatVal).div(1e18);//
            uint diff = realPrice>price? realPrice-price:price-realPrice;
            require(diff.mul(1000)<realPrice.mul(5),"price not match chainlink");
            realPrice = price;
        }else{
            realPrice  = makes[makeID].price;
        }
        takeID = takesN;
        takes[takeID] = STake(makeID, msg.sender, vol, Status.None, now.add(config[_expiry_]),link,realPrice);
        takesN++;
        emit Take(takeID, makeID, msg.sender, vol, takes[takeID].expiry,link,realPrice);*/
    }

    //event Take(uint indexed takeID, uint indexed makeID, address indexed taker, uint vol, uint expiry,string link,uint realPrice);

    function cancelTake(uint256 takeID)
        external
        virtual
        nonReentrant
        returns (uint256 vol)
    {
        require(takes[takeID].taker != address(0), "Nonexistent take order");
        uint256 makeID = takes[takeID].makeID;
        (address buyer, address seller) = makes[makeID].isBid
            ? (makes[makeID].maker, takes[takeID].taker)
            : (takes[takeID].taker, makes[makeID].maker);

        if (msg.sender == buyer) {
            require(
                takes[takeID].status <= Status.None,
                "buyer can cancel neither Status.None nor Status.Paid take order"
            );
        } else if (msg.sender == seller) {
            require(
                takes[takeID].status == Status.None,
                "seller can only cancel Status.None take order"
            );
            require(
                takes[takeID].expiry < now,
                "seller can only cancel expired take order"
            );
        } else revert("only buyer or seller");
        if (!makes[makeID].isBid) biddingN[buyer] = biddingN[buyer].sub(1);
        vol = takes[takeID].vol;
        IERC20(makes[makeID].asset).safeTransfer(seller, vol);

        makes[makeID].pending = makes[makeID].pending.sub(vol);
        takes[takeID].status = Status.Cancel;

        if (makes[makeID].isBid) {
            if (makes[makeID].pending == 0 && makes[makeID].remain == 0)
                biddingN[buyer] = biddingN[buyer].sub(1);
        }

        emit CancelTake(takeID, makeID, msg.sender, vol);
    }

    event CancelTake(
        uint256 indexed takeID,
        uint256 indexed makeID,
        address indexed sender,
        uint256 vol
    );

    // function paid(uint256 takeID) external virtual {
    //     require(takes[takeID].taker != address(0), "Nonexistent take order");
    //     require(takes[takeID].status == Status.None, "only Status.None");
    //     uint256 makeID = takes[takeID].makeID;
    //     address buyer = makes[makeID].isBid
    //         ? makes[makeID].maker
    //         : takes[takeID].taker;
    //     require(msg.sender == buyer, "only buyer");

    //     takes[takeID].status = Status.Paid;
    //     takes[takeID].expiry = now.add(config[_expiry_]);

    //     emit Paid(takeID, makeID, buyer);
    // }

    // event Paid(
    //     uint256 indexed takeID,
    //     uint256 indexed makeID,
    //     address indexed buyer
    // );

    function deliver(uint256 takeID)
        external
        virtual
        nonReentrant
        returns (uint256 vol)
    {
        require(takes[takeID].taker != address(0), "Nonexistent take order");
        require(
            takes[takeID].status <= Status.None,
            "only Status.None or Paid"
        );
        uint256 makeID = takes[takeID].makeID;
        (address buyer, address seller) = makes[makeID].isBid
            ? (makes[makeID].maker, takes[takeID].taker)
            : (takes[takeID].taker, makes[makeID].maker);
        require(msg.sender == seller, "only seller");
        vol = takes[takeID].vol;

        uint256 fee = _payFee(
            takeID,
            makes[makeID].asset,
            vol,
            makes[makeID].currency
        );
        IERC20(makes[makeID].asset).safeTransfer(buyer, vol.sub(fee));

        makes[makeID].pending = makes[makeID].pending.sub(vol);
        takes[takeID].status = Status.Done;
        takes[takeID].expiry = now.add(config[_preDoneExpiry_]);

        if (
            (!makes[makeID].isBid) ||
            (makes[makeID].remain == 0 && makes[makeID].pending == 0)
        ) biddingN[buyer] = biddingN[buyer].sub(1);

        emit Deliver(takeID, makeID, seller, vol);
        emit ArbitrateLib.Deal(takeID, makes[makeID].asset, vol);
    }

    event Deliver(
        uint256 indexed takeID,
        uint256 indexed makeID,
        address indexed seller,
        uint256 vol
    );

    //event Deal(uint indexed takeID, address indexed asset, uint vol);

    function merchantOk(uint256 takeID) external virtual nonReentrant {
        ArbitrateLib.merchantOk(makes, makeExs, takes, config, takeID);
        /*uint makeID = takes[takeID].makeID;
        require(makes[makeID].maker == msg.sender, 'must be maker');
        require(takes[takeID].status == Status.Done, 'only Status.Done');
        takes[takeID].status == Status.MerchantOk;   */
    }

    function claimTradingMargin(uint256 takeID) external virtual nonReentrant {
        ArbitrateLib.claimTradingMargin(makes, makeExs, takes, config, takeID);
        /*require(takes[takeID].taker == msg.sender, 'must be taker');
        require(takes[takeID].status == Status.MerchantOk ||((takes[takeID].status == Status.Done)&&(now>takes[takeID].expiry)&&makeExs[takes[takeID].makeID].tradingMargin>0),"No claimTradingMargin");
        takes[takeID].status == Status.ClaimTradingMargin; 
        ITradingStakePool(config[_tradingPool_]).withdraw(msg.sender,makeExs[takes[takeID].makeID].tradingMargin); */
    }

    function appeal(uint256 takeID) external virtual nonReentrant {
        ArbitrateLib.appeal(
            makes,
            makeExs,
            takes,
            config,
            appealInfos,
            takeID,
            arbiters,
            isArbiter
        ); //mapping(uint =>AppealInfo) public appealInfos
        /*require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status == Status.Paid, 'only Status.Paid');
        uint makeID = takes[takeID].makeID;
        require(msg.sender == makes[makeID].maker || msg.sender == takes[takeID].taker, 'only maker or taker');
        require(takes[takeID].expiry < now, 'only expired');
        IERC20(address(config[_feeToken_])).safeTransferFrom(msg.sender, address(config[_vault_]), config[_feeVolume_]);
        takes[takeID].status = Status.Appeal;
        appealAddress[takeID] = msg.sender; 
        emit Appeal(takeID, makeID, msg.sender, takes[takeID].vol);*/
    }

    //event Appeal(uint indexed takeID, uint indexed makeID, address indexed sender, uint vol);

    function arbitrate(
        uint256 takeID,
        Status winner,
        Status appealFeeTo,
        Status punishSide,
        uint256 punishVol,
        Status punishTo
    ) external virtual nonReentrant returns (uint256 vol) {
        ArbiterPara memory arbiterPara = ArbiterPara(
            takeID,
            winner,
            appealFeeTo,
            punishSide,
            punishVol,
            punishTo
        );

        vol = ArbitrateLib.arbitrate(
            makes,
            makeExs,
            takes,
            config,
            appealInfos,
            biddingN,
            arbiterPara
        );
        /*      require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status == Status.Appeal, 'only Status.Appeal');
        require(isArbiter[msg.sender], 'only arbiter');
        uint makeID = takes[takeID].makeID;
        (address buyer, address seller) = makes[makeID].isBid ? (makes[makeID].maker, takes[takeID].taker) : (takes[takeID].taker, makes[makeID].maker);
        
        vol = takes[takeID].vol;
        if(status == Status.Buyer) {
            uint fee = _payFee(takeID, makes[makeID].asset, vol);
            IERC20(makes[makeID].asset).safeTransfer(buyer, vol.sub(fee));
            emit Deal(takeID,makes[makeID].asset,vol);
        } else if(status == Status.Seller) {
            IERC20(makes[makeID].asset).safeTransfer(seller, vol);
            if(staking.isContract())
                IStaking(staking).punish(buyer);
        } else
            revert('status should be Buyer or Seller');
        makes[makeID].pending = makes[makeID].pending.sub(vol);
        takes[takeID].status = status;
        if ((!makes[makeID].isBid) || (makes[makeID].remain==0 && makes[makeID].pending == 0))
            biddingN[buyer] = biddingN[buyer].sub(1);
        emit Arbitrate(takeID, makeID, msg.sender, vol, status);*/
    }

    //    event Arbitrate(uint indexed takeID, uint indexed makeID, address indexed arbiter, uint vol, Status status);

    function _feeBuf() internal view returns (uint256) {
        uint256 spanBuf = config[_spanBuf_];
        return
            spanBuf
                .sub0(now.sub(config[_lastUpdateBuf_]))
                .mul(config[_feeBuf_])
                .div(spanBuf);
    }

    function price1() public view returns (uint256) {
        return _feeBuf().mul(1e18).div0(config[_rewardOfSpan_]);
    }

    function price() public view returns (uint256 p1, uint256 p2) {
        (p1, p2) = ArbitrateLib.price(config);
        /*(p1,p2) = priceEth();
        address tokenA = address(config[_pairTokenA_]);
        address usd = address(config[_usd_]);
        address pair = IUniswapV2Factory(config[_swapFactory_]).getPair(tokenA,usd);
        uint volA = IERC20(tokenA).balanceOf(pair);
        uint volU = IERC20(usd).balanceOf(pair);
        p1 = p1.mul(volU).div(volA);
        p2 = p2.mul(volU).div(volA);*/
    }

    function priceEth() public view returns (uint256 p1, uint256 p2) {
        (p1, p2) = ArbitrateLib.priceEth(config);
        /*p1 = price1();
        
        address tokenA = address(config[_pairTokenA_]);
        address tokenR = address(config[_rewardToken_]);
        address pair = IUniswapV2Factory(config[_swapFactory_]).getPair(tokenA, tokenR);
        if(pair == address(0) || IERC20(tokenA).balanceOf(pair) == 0)
            p2 = 0;
        else
            p2 = IERC20(tokenA).balanceOf(pair).mul(1e18).div(IERC20(tokenR).balanceOf(pair));*/
    }

    function earned(address acct) public view returns (uint256) {
        return getConfigA(_rewards_, acct);
    }

    function lockEnd(address acct) public view returns (uint256) {
        return getConfigA(_lockEnd_, acct);
    }

    function locked(address acct) public view returns (uint256) {
        uint256 end = lockEnd(acct);
        return getConfigA(_locked_, acct).mul(end.sub0(now)).div0(end);
    }

    function claimable(address acct) public view returns (uint256) {
        return earned(acct).sub(locked(acct));
    }

    function claim() external {
        address acct = msg.sender;
        IERC20(config[_rewardToken_]).safeTransfer(acct, claimable(acct));
        _setConfig(_rewards_, acct, locked(acct));
    }

    function claimFor_(address acct) external {
        require(getConfigA(_claimFor_, msg.sender) == 1, "only claimForer");
        IERC20(config[_rewardToken_]).safeTransfer(acct, claimable(acct));
        _setConfig(_rewards_, acct, locked(acct));
    }

    function payFee(
        uint256 takeID,
        address asset,
        uint256 vol,
        uint256 makeID
    ) public returns (uint256 fee) {
        require(
            msg.sender == address(this),
            "must msg.sender == address(this)"
        );
        fee = _payFee(takeID, asset, vol, makes[makeID].currency);
    }

    function _payFee(
        uint256 takeID,
        address asset,
        uint256 vol,
        bytes32 currency
    ) internal returns (uint256 fee) {
        if (isCustomFiat(currency)) {
            fee = vol.mul(fiatFeeMap[currency]).div(1e6);
        } else {
            fee = vol.mul(config[_feeRate_]).div(1e18);
        }
        if (fee == 0) return fee;
        address rewardToken = address(config[_rewardToken_]);
        (
            IUniswapV2Router01 router,
            address tokenA,
            uint256 amt
        ) = _swapToPairTokenA(asset, fee);

        uint256 amt1 = amt.mul(config[_feeRatio1_]).div(1e18);
        IERC20(tokenA).safeTransfer(address(config[_vault_]), amt1);
        uint256 feeBuf = _feeBuf();
        vol = amt1.mul(config[_rewardOfSpan_]).div0(feeBuf);
        IERC20(rewardToken).safeTransferFrom(
            address(config[_mine_]),
            address(this),
            vol
        );
        config[_feeBuf_] = feeBuf.add(amt1);
        config[_lastUpdateBuf_] = now;

        if (amt.sub(amt1) > 0) {
            address[] memory path = new address[](2);
            path[0] = tokenA;
            path[1] = rewardToken;
            IERC20(tokenA).safeApprove_(address(router), amt.sub(amt1));
            uint256[] memory amounts = router.swapExactTokensForTokens(
                amt.sub(amt1),
                0,
                path,
                address(this),
                now
            );
            payFee2(takeID, vol, amounts[1]);
        }
        IVault(config[_vault_]).rebase();
    }

    event FeeReward(uint256 indexed takeID, uint256 makeVol, uint256 takeVol);
    event RecommendReward(uint256 indexed takeID, uint256 vol);

    function payFee2(
        uint256 takeID,
        uint256 v1,
        uint256 v2
    ) internal {
        uint256 ratio = config[_rewardRatioMaker_];
        uint256 v = v1.add(v2);
        if (takes[takeID].recommender != address(0)) {
            uint256 vRecommender = v.mul(ratio).div(2e18); //==maker vol   50%
            emit FeeReward(
                takeID,
                vRecommender,
                v.mul(uint256(1e18).sub(ratio)).div(1e18)
            );
            emit RecommendReward(takeID, vRecommender);
            //address rewardToken = address(config[_rewardToken_]);
            //IERC20(rewardToken).safeTransfer(takes[takeID].recommender,vRecommender);
            uint256 recommReward = getConfigA(
                _rewards_,
                takes[takeID].recommender
            );
            _setConfig(
                _rewards_,
                takes[takeID].recommender,
                recommReward.add(vRecommender)
            );
            v1 = v;
            v2 = 0;
            _updateReward(
                makes[takes[takeID].makeID].maker,
                v1,
                v2,
                ratio.div(2)
            );
            _updateReward(
                takes[takeID].taker,
                v1,
                v2,
                uint256(1e18).sub(ratio)
            );
        } else {
            emit FeeReward(
                takeID,
                v.mul(ratio).div(1e18),
                v.mul(uint256(1e18).sub(ratio)).div(1e18)
            );
            v1 = v;
            v2 = 0;
            _updateReward(makes[takes[takeID].makeID].maker, v1, v2, ratio);
            _updateReward(
                takes[takeID].taker,
                v1,
                v2,
                uint256(1e18).sub(ratio)
            );
        }
    }

    function _updateReward(
        address acct,
        uint256 v1,
        uint256 v2,
        uint256 ratio
    ) internal {
        v1 = v1.mul(ratio).div(1e18);
        v2 = v2.mul(ratio).div(1e18);
        uint256 lkd = locked(acct);
        uint256 end = lockEnd(acct);
        end = end
            .sub0(now)
            .mul(lkd)
            .add(getConfig(_spanLock_).mul(v1))
            .div(lkd.add(v1))
            .add(now);
        _setConfig(_locked_, acct, lkd.add(v1).mul(end).div(end.sub(now)));
        _setConfig(_lockEnd_, acct, end);
        _setConfig(_rewards_, acct, earned(acct).add(v1).add(v2));
    }

    function _swapToPairTokenA(address asset, uint256 fee)
        internal
        returns (
            IUniswapV2Router01 router,
            address tokenA,
            uint256 amt
        )
    {
        (router, tokenA, amt) = ArbitrateLib._swapToPairTokenA(
            config,
            asset,
            fee
        );
        /*router = IUniswapV2Router01(config[_swapRouter_]);
        tokenA = address(config[_pairTokenA_]);
        if(tokenA == asset)
            return (router, asset, fee);
        IERC20(asset).safeApprove_(address(router), fee);
        if(IUniswapV2Factory(config[_swapFactory_]).getPair(asset, tokenA) != address(0)) {
            address[] memory path = new address[](2);
            path[0] = asset;
            path[1] = tokenA;
            uint[] memory amounts = router.swapExactTokensForTokens(fee, 0, path, address(this), now);
            amt = amounts[1];
        } else {
            address[] memory path = new address[](3);
            path[0] = asset;
            path[1] = router.WETH();
            path[2] = tokenA;
            uint[] memory amounts = router.swapExactTokensForTokens(fee, 0, path, address(this), now);
            amt = amounts[2];
        }*/
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[41] private ______gap;
}

library ArbitrateLib {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 internal constant _expiry_ = "expiry";
    //bytes32 internal constant _feeTo_       = "feeTo";
    bytes32 internal constant _feeToken_ = "feeToken";
    bytes32 internal constant _feeVolume_ = "feeVolume";
    bytes32 internal constant _feeRate_ = "feeRate";
    bytes32 internal constant _feeRatio1_ = "feeRatio1";
    bytes32 internal constant _feeBuf_ = "feeBuf";
    bytes32 internal constant _lastUpdateBuf_ = "lastUpdateBuf";
    bytes32 internal constant _spanBuf_ = "spanBuf";
    bytes32 internal constant _spanLock_ = "spanLock";
    bytes32 internal constant _rewardOfSpan_ = "rewardOfSpan";
    bytes32 internal constant _rewardRatioMaker_ = "rewardRatioMaker";
    bytes32 internal constant _rewardToken_ = "rewardToken";
    bytes32 internal constant _rewards_ = "rewards";
    bytes32 internal constant _locked_ = "locked";
    bytes32 internal constant _lockEnd_ = "lockEnd";
    /*  bytes32 internal constant _rebaseTime_  = "rebaseTime";
    bytes32 internal constant _rebasePeriod_= "rebasePeriod";
    bytes32 internal constant _factorPrice20_   = "factorPrice20";
    bytes32 internal constant _lpTknMaxRatio_   = "lpTknMaxRatio";
    bytes32 internal constant _lpCurMaxRatio_   = "lpCurMaxRatio";*/
    bytes32 internal constant _vault_ = "vault";
    bytes32 internal constant _pairTokenA_ = "pairTokenA";
    bytes32 internal constant _swapFactory_ = "swapFactory";
    bytes32 internal constant _swapRouter_ = "swapRouter";
    bytes32 internal constant _mine_ = "mine";
    bytes32 internal constant _assetList_ = "assetList";
    bytes32 internal constant _assetFreeLimit_ = "assetFreeLimit";
    bytes32 internal constant _usd_ = "usd";
    bytes32 internal constant _bank_ = "bank";
    bytes32 internal constant _merchantPool_ = "merchantPool";
    bytes32 internal constant _tradingPool_ = "tradingPool";
    bytes32 internal constant _preDoneExpiry_ = "preDoneExpiry"; //7days
    bytes32 internal constant _priceAndRate_ = "priceAndRate";
    // bytes32 internal constant _babtoken_ = "babtoken";

    struct Tmpval {
        address buyer;
        address seller;
        uint256 tradingMargin;
    }

    bytes32 internal constant _claimFor_ = "claimFor";

    function getRandArbiter(
        address[] storage arbiters,
        mapping(address => bool) storage isArbiter
    ) public view returns (address randArbiter) {
        uint256 hash = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1 - (block.difficulty % 100))
                )
            )
        );
        hash = hash % arbiters.length;
        uint256 cnt = 0;
        randArbiter = address(0);
        while (true) {
            if (isArbiter[arbiters[hash]]) {
                randArbiter = arbiters[hash];
                break;
            }
            hash = (hash + 1) % arbiters.length;
            cnt++;
            if (cnt >= arbiters.length) break;
        }
    }

    function appeal(
        mapping(uint256 => SMake) storage makes,
        mapping(uint256 => SMakeEx) storage makeExs,
        mapping(uint256 => STake) storage takes,
        mapping(bytes32 => uint256) storage config,
        mapping(uint256 => AppealInfo) storage appealInfos,
        uint256 takeID,
        address[] storage arbiters,
        mapping(address => bool) storage isArbiter
    ) external virtual {
        // DOTC dotc = DOTC(address(this));
        STake memory take = takes[takeID];
        require(take.taker != address(0), "Nonexistent take order");
        if (take.status == Status.Paid) {
            //normal appeal or merchant appeal
            uint256 makeID = take.makeID;
            require(
                msg.sender == makes[makeID].maker || msg.sender == take.taker,
                "only maker or taker"
            );

            (, address seller) = makes[makeID].isBid
                ? (makes[makeID].maker, takes[takeID].taker)
                : (takes[takeID].taker, makes[makeID].maker);
            if (msg.sender != seller)
                require(take.expiry < now, "only expired");
            IERC20(address(config[_feeToken_])).safeTransferFrom(
                msg.sender,
                address(config[_bank_]),
                config[_feeVolume_]
            ); //tmp bank ,appeal 5PEX, arbitrate to vault or seller or buyer
            if (makeExs[makeID].tradingMargin == 0)
                takes[takeID].status = Status.Appeal;
            else takes[takeID].status = Status.MerchantAppeal;
            //appealAddress[takeID] = msg.sender;
            appealInfos[takeID].takeID = takeID;
            appealInfos[takeID].appeal = msg.sender;
            appealInfos[takeID].arbiter = getRandArbiter(arbiters, isArbiter);
            appealInfos[takeID].isDeliver = false;

            emit Appeal(
                takeID,
                makeID,
                msg.sender,
                take.vol,
                appealInfos[takeID].arbiter
            );
        } else {
            //merchant appeal
            require(take.status == Status.Done, "only Status.Done");
            uint256 makeID = take.makeID;
            require(
                msg.sender == makes[makeID].maker || msg.sender == take.taker,
                "only maker or taker"
            );

            //        (, address seller) = makes[makeID].isBid ? (makes[makeID].maker, takes[takeID].taker) : (takes[takeID].taker, makes[makeID].maker);
            require(
                makeExs[makeID].tradingMargin > 0 &&
                    msg.sender == makes[makeID].maker,
                "must be merchat"
            );
            require(now < take.expiry, "only expired");
            IERC20(address(config[_feeToken_])).safeTransferFrom(
                msg.sender,
                address(config[_bank_]),
                config[_feeVolume_]
            ); //tmp bank ,appeal 5PEX, arbitrate to vault or seller or buyer
            takes[takeID].status = Status.MerchantAppeal;
            //appealAddress[takeID] = msg.sender;
            appealInfos[takeID].takeID = takeID;
            appealInfos[takeID].appeal = msg.sender;
            appealInfos[takeID].arbiter = getRandArbiter(arbiters, isArbiter);
            appealInfos[takeID].isDeliver = true;

            emit Appeal(
                takeID,
                makeID,
                msg.sender,
                take.vol,
                appealInfos[takeID].arbiter
            );
        }
    }

    event Appeal(
        uint256 indexed takeID,
        uint256 indexed makeID,
        address indexed sender,
        uint256 vol,
        address arbiter
    );

    function merchantOk(
        mapping(uint256 => SMake) storage makes,
        mapping(uint256 => SMakeEx) storage makeExs,
        mapping(uint256 => STake) storage takes,
        mapping(bytes32 => uint256) storage config,
        uint256 takeID
    ) external virtual {
        uint256 makeID = takes[takeID].makeID;
        require(makes[makeID].maker == msg.sender, "must be maker");
        require(takes[takeID].status == Status.Done, "only Status.Done");
        uint256 tradingMargin = makeExs[makeID].tradingMargin;
        require(tradingMargin > 0, "only tradingMargin>0");
        require(now < takes[takeID].expiry, "now must < expiry");
        //takes[takeID].status = Status.MerchantOk;
        emit MerchantOk(takeID);
        takes[takeID].status = Status.ClaimTradingMargin;
        ITradingStakePool(config[_tradingPool_]).withdraw(
            takes[takeID].taker,
            tradingMargin
        );
        emit ClaimTradingMargin(takeID, tradingMargin);
    }

    event MerchantOk(uint256 takeID);

    struct DataTmp {
        //stack too deep
        uint256 realPrice;
        uint256 priceType;
        uint256 price;
        uint8 decimals;
        uint256 rate;
    }

    function takeLib(
        mapping(uint256 => SMake) storage makes,
        mapping(uint256 => SMakeEx) storage makeExs,
        mapping(uint256 => STake) storage takes,
        mapping(bytes32 => uint256) storage config,
        mapping(address => uint256) storage biddingN,
        TakePara memory takePara /*uint makeID, uint volume,string memory link,uint price,address recommender*/
    ) external virtual returns (uint256 takeID, uint256 vol) {
        DOTC dotc = DOTC(address(this));
        //uint makeID, uint volume,string memory link,uint price,address recommender;
        uint256 makeID = takePara.makeID;
        require(makes[makeID].maker != address(0), "Nonexistent make order");
        require(makes[makeID].remain > 0, "make.remain should > 0");
        require(
            makes[makeID].minVol <= takePara.volume,
            "volume must > minVol"
        );
        require(
            makes[makeID].maxVol >= takePara.volume,
            "volume must < maxVol"
        );
        //require((makes[makeID].maker != takePara.recommender)&&(msg.sender != takePara.recommender), 'recommender must not maker or taker');
        if (makeExs[makeID].tradingMargin > 0) {
            //config[_tradingPool_]
            IERC20(address(config[_feeToken_])).safeTransferFrom(
                msg.sender,
                address(this),
                makeExs[makeID].tradingMargin
            );
            if (
                IERC20(address(config[_feeToken_])).allowance(
                    address(this),
                    address(config[_tradingPool_])
                ) < makeExs[makeID].tradingMargin
            )
                IERC20(address(config[_feeToken_])).approve(
                    address(config[_tradingPool_]),
                    uint256(-1)
                );
            ITradingStakePool(address(config[_tradingPool_])).stake(
                msg.sender,
                makeExs[makeID].tradingMargin
            );
        } else if (
            takePara.volume >
            dotc.getConfigA(_assetFreeLimit_, makes[makeID].asset)
        )
            require(
                IStaking(dotc.staking()).enough(msg.sender),
                "GT Limit,must stake"
            );
        vol = takePara.volume;
        if (vol > makes[makeID].remain) vol = makes[makeID].remain;
        if (!makes[makeID].isBid) {
            //require(staking == address(0) || IStaking(staking).enough(msg.sender));
            biddingN[msg.sender]++;
        } else
            IERC20(makes[makeID].asset).safeTransferFrom(
                msg.sender,
                address(this),
                vol
            );

        makes[makeID].remain = makes[makeID].remain.sub(vol);
        makes[makeID].pending = makes[makeID].pending.add(vol);

        DataTmp memory dataTmp;
        dataTmp.priceType = makeExs[makeID].priceType;
        if (dataTmp.priceType != 0) {
            (dataTmp.price, dataTmp.decimals, dataTmp.rate) = IPriceAndRate(
                address(config[_priceAndRate_])
            ).getPriceAndRate(makes[makeID].asset, makes[makeID].currency);
            require(dataTmp.price > 0, "No the asset");
            require(dataTmp.rate > 0, "No the currency");
            if (dataTmp.priceType == 1) {
                if (makeExs[makeID].floatVal >= 0)
                    dataTmp.realPrice = dataTmp
                        .price
                        .mul(dataTmp.rate)
                        .div(uint128(10)**(dataTmp.decimals))
                        .add(uint256(makeExs[makeID].floatVal)); //1170e18 *6.71e18
                else
                    dataTmp.realPrice = dataTmp
                        .price
                        .mul(dataTmp.rate)
                        .div(uint128(10)**(dataTmp.decimals))
                        .sub(uint256(0 - makeExs[makeID].floatVal)); //1170e18 *6.71e18
            } else if (dataTmp.priceType == 2) {
                if (makeExs[makeID].floatVal >= 0)
                    dataTmp.realPrice = dataTmp
                        .price
                        .mul(dataTmp.rate)
                        .div(uint128(10)**(dataTmp.decimals))
                        .mul(
                            uint256(1e18).add(uint256(makeExs[makeID].floatVal))
                        )
                        .div(1e18); //
                else
                    dataTmp.realPrice = dataTmp
                        .price
                        .mul(dataTmp.rate)
                        .div(uint128(10)**(dataTmp.decimals))
                        .mul(
                            uint256(1e18).sub(
                                uint256(0 - makeExs[makeID].floatVal)
                            )
                        )
                        .div(1e18); //
            }
            uint256 diff = dataTmp.realPrice > takePara.price
                ? dataTmp.realPrice - takePara.price
                : takePara.price - dataTmp.realPrice;
            require(
                diff.mul(1000) < dataTmp.realPrice.mul(5),
                "price not match chainlink"
            );
            dataTmp.realPrice = takePara.price;
        } else {
            dataTmp.realPrice = makes[makeID].price;
        }
        takeID = dotc.takesN();
        takes[takeID] = STake(
            makeID,
            msg.sender,
            vol,
            Status.None,
            now.add(config[_expiry_]),
            takePara.link,
            dataTmp.realPrice,
            takePara.recommender
        );
        //takesN++;
        emit Take(
            takeID,
            makeID,
            msg.sender,
            vol,
            takes[takeID].expiry,
            takePara.link,
            dataTmp.realPrice,
            takePara.recommender
        );
    }

    event Take(
        uint256 indexed takeID,
        uint256 indexed makeID,
        address indexed taker,
        uint256 vol,
        uint256 expiry,
        string link,
        uint256 realPrice,
        address recommender
    );

    function claimTradingMargin(
        mapping(uint256 => SMake) storage makes,
        mapping(uint256 => SMakeEx) storage makeExs,
        mapping(uint256 => STake) storage takes,
        mapping(bytes32 => uint256) storage config,
        uint256 takeID
    ) external virtual {
        makes;
        require(takes[takeID].taker == msg.sender, "must be taker");
        uint256 tradingMargin = makeExs[takes[takeID].makeID].tradingMargin;
        require(
            takes[takeID].status == Status.MerchantOk ||
                ((takes[takeID].status == Status.Done) &&
                    (now > takes[takeID].expiry) &&
                    tradingMargin > 0),
            "No claimTradingMargin"
        );
        takes[takeID].status = Status.ClaimTradingMargin;
        ITradingStakePool(config[_tradingPool_]).withdraw(
            msg.sender,
            tradingMargin
        );
        emit ClaimTradingMargin(takeID, tradingMargin);
    }

    event ClaimTradingMargin(uint256 takeID, uint256 tradingMargin);

    function arbitrate(
        mapping(uint256 => SMake) storage makes,
        mapping(uint256 => SMakeEx) storage makeExs,
        mapping(uint256 => STake) storage takes,
        mapping(bytes32 => uint256) storage config,
        mapping(uint256 => AppealInfo) storage ais,
        mapping(address => uint256) storage biddingN,
        ArbiterPara memory ap /*uint takeID, Status winner,Status assetTo,Status appealFeeTo,Status punishSide,uint punishVol*/ /*nonReentrant*/
    ) external virtual returns (uint256 vol) {
        DOTC dotc = DOTC(address(this));
        uint256 takeID = ap.takeID;
        STake memory take = takes[takeID];
        uint256 makeID = take.makeID;
        SMake memory make = makes[makeID];
        require(take.taker != address(0), "Nonexistent take order");
        require(
            take.status == Status.Appeal ||
                take.status == Status.MerchantAppeal,
            "only Status.Appeal or Status.MerchantAppeal"
        );
        require(dotc.isArbiter(msg.sender), "only arbiter");
        require(ais[takeID].arbiter == msg.sender, "only the arbiter");
        require(ap.winner != ap.punishSide, "Can't punish winner");
        ais[takeID].winner = ap.winner;
        ais[takeID].appealFeeTo = ap.appealFeeTo;
        ais[takeID].punishSide = ap.punishSide;
        ais[takeID].punishVol = ap.punishVol;
        ais[takeID].punishTo = ap.punishTo;

        Tmpval memory tmpval; //deep stack
        {
            (tmpval.buyer, tmpval.seller) = make.isBid
                ? (make.maker, take.taker)
                : (take.taker, make.maker);
            tmpval.tradingMargin = makeExs[makeID].tradingMargin;
        }
        if (take.status == Status.Appeal) {
            vol = take.vol;
            if (ap.winner == Status.Buyer) {
                uint256 fee = dotc.payFee(takeID, make.asset, vol, makeID);
                IERC20(make.asset).safeTransfer(tmpval.buyer, vol.sub(fee));
                emit Deal(takeID, make.asset, vol);
            } else if (ap.winner == Status.Seller) {
                IERC20(make.asset).safeTransfer(tmpval.seller, vol);
                //if(dotc.staking().isContract())
                //    IStaking(dotc.staking()).punish(buyer);
            } else revert("status should be Buyer or Seller");

            //appeal fee 5PEX to:
            {
                //address appealFeeToAddr;
                if (ap.appealFeeTo == Status.Buyer)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        tmpval.buyer,
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
                else if (ap.appealFeeTo == Status.Seller)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        tmpval.seller,
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
                else if (ap.appealFeeTo == Status.Vault)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        address(config[_vault_]),
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
            }

            if (dotc.staking().isContract()) {
                //punish PEX
                if (ap.punishSide == Status.Buyer)
                    IStaking(dotc.staking()).punish(tmpval.buyer, ap.punishVol);
                else if (ap.punishSide == Status.Seller)
                    IStaking(dotc.staking()).punish(
                        tmpval.seller,
                        ap.punishVol
                    );
            }

            makes[makeID].pending = makes[makeID].pending.sub(vol);
            takes[takeID].status = ap.winner;

            if (
                (!makes[makeID].isBid) ||
                (makes[makeID].remain == 0 && makes[makeID].pending == 0)
            ) biddingN[tmpval.buyer] = biddingN[tmpval.buyer].sub(1);

            emit Arbitrate1(
                takeID,
                makeID,
                msg.sender,
                vol,
                ap.winner,
                ap /*ap.winner,ap.appealFeeTo,ap.punishSide,ap.punishVol*/
            );
        } else {
            if (!ais[takeID].isDeliver) {
                vol = take.vol;
                if (ap.winner == Status.Buyer) {
                    uint256 fee = dotc.payFee(takeID, make.asset, vol, makeID);
                    IERC20(make.asset).safeTransfer(tmpval.buyer, vol.sub(fee));
                    emit Deal(takeID, make.asset, vol);
                } else if (ap.winner == Status.Seller) {
                    IERC20(make.asset).safeTransfer(tmpval.seller, vol);
                    //if(dotc.staking().isContract())
                    //    IStaking(dotc.staking()).punish(buyer);
                } else revert("status should be Buyer or Seller");
            }

            //appeal fee 5PEX to:
            {
                //address appealFeeToAddr;
                if (ap.appealFeeTo == Status.Buyer)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        tmpval.buyer,
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
                else if (ap.appealFeeTo == Status.Seller)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        tmpval.seller,
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
                else if (ap.appealFeeTo == Status.Vault)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        address(config[_vault_]),
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
            }
            address punishTo;
            if (ap.punishTo == Status.Buyer) punishTo = tmpval.buyer;
            else if (ap.punishTo == Status.Seller) punishTo = tmpval.seller;
            else punishTo = address(config[_vault_]);

            if (ap.punishSide == Status.Buyer) {
                if (make.maker == tmpval.buyer)
                    IMerchantStakePool(config[_merchantPool_]).punish(
                        tmpval.buyer,
                        punishTo,
                        ap.punishVol
                    );
                else {
                    ITradingStakePool(config[_tradingPool_]).punish(
                        tmpval.buyer,
                        punishTo,
                        ap.punishVol
                    );
                    ITradingStakePool(config[_tradingPool_]).withdraw(
                        tmpval.buyer,
                        tmpval.tradingMargin.sub(ap.punishVol)
                    );
                }
            } else if (ap.punishSide == Status.Seller) {
                if (make.maker == tmpval.seller)
                    IMerchantStakePool(config[_merchantPool_]).punish(
                        tmpval.seller,
                        punishTo,
                        ap.punishVol
                    );
                else {
                    ITradingStakePool(config[_tradingPool_]).punish(
                        tmpval.seller,
                        punishTo,
                        ap.punishVol
                    );
                    ITradingStakePool(config[_tradingPool_]).withdraw(
                        tmpval.seller,
                        tmpval.tradingMargin.sub(ap.punishVol)
                    );
                }
            }
            takes[takeID].status = Status.MerchantAppealDone;
            emit Arbitrate1(
                takeID,
                makeID,
                msg.sender,
                vol,
                ap.winner,
                ap /*ap.winner,ap.appealFeeTo,ap.punishSide,ap.punishVol*/
            );
        }
    }

    event Arbitrate1(
        uint256 indexed takeID,
        uint256 indexed makeID,
        address indexed arbiter,
        uint256 vol,
        Status winner,
        ArbiterPara arbiterPara /* Status status,Status appealFeeTo,Status punishSide,uint punishVol*/
    );
    event Deal(uint256 indexed takeID, address indexed asset, uint256 vol);

    function _swapToPairTokenA(
        mapping(bytes32 => uint256) storage config,
        address asset,
        uint256 fee
    )
        internal
        returns (
            IUniswapV2Router01 router,
            address tokenA,
            uint256 amt
        )
    {
        router = IUniswapV2Router01(config[_swapRouter_]);
        tokenA = address(config[_pairTokenA_]);
        if (tokenA == asset) return (router, asset, fee);
        IERC20(asset).safeApprove_(address(router), fee);
        if (
            IUniswapV2Factory(config[_swapFactory_]).getPair(asset, tokenA) !=
            address(0)
        ) {
            address[] memory path = new address[](2);
            path[0] = asset;
            path[1] = tokenA;
            uint256[] memory amounts = router.swapExactTokensForTokens(
                fee,
                0,
                path,
                address(this),
                now
            );
            amt = amounts[1];
        } else {
            address[] memory path = new address[](3);
            path[0] = asset;
            path[1] = router.WETH();
            path[2] = tokenA;
            uint256[] memory amounts = router.swapExactTokensForTokens(
                fee,
                0,
                path,
                address(this),
                now
            );
            amt = amounts[2];
        }
    }

    function price(mapping(bytes32 => uint256) storage config)
        public
        view
        returns (uint256 p1, uint256 p2)
    {
        DOTC dotc = DOTC(address(this));
        (p1, p2) = dotc.priceEth();
        address tokenA = address(config[_pairTokenA_]);
        address usd = address(config[_usd_]);
        address pair = IUniswapV2Factory(config[_swapFactory_]).getPair(
            tokenA,
            usd
        );
        uint256 volA = IERC20(tokenA).balanceOf(pair);
        uint256 volU = IERC20(usd).balanceOf(pair);
        p1 = p1.mul(volU).div(volA);
        p2 = p2.mul(volU).div(volA);
    }

    function priceEth(mapping(bytes32 => uint256) storage config)
        public
        view
        returns (uint256 p1, uint256 p2)
    {
        DOTC dotc = DOTC(address(this));
        p1 = dotc.price1();

        address tokenA = address(config[_pairTokenA_]);
        address tokenR = address(config[_rewardToken_]);
        address pair = IUniswapV2Factory(config[_swapFactory_]).getPair(
            tokenA,
            tokenR
        );
        if (pair == address(0) || IERC20(tokenA).balanceOf(pair) == 0) p2 = 0;
        else
            p2 = IERC20(tokenA).balanceOf(pair).mul(1e18).div(
                IERC20(tokenR).balanceOf(pair)
            );
    }
}

interface IPriceAndRate {
    function getPriceAndRate(address token, bytes32 currency)
        external
        view
        returns (
            uint256 price,
            uint8 decimals,
            uint256 rate
        );
}

interface ISBT721 {
    function balanceOf(address owner) external view returns (uint256);
}

interface IStaking {
    function enough(address buyer) external view returns (bool);

    function punish(address buyer, uint256 vol) external;
}

interface IMerchantStakePool {
    function isMerchant(address account) external view returns (bool);

    function punish(
        address from,
        address to,
        uint256 vol
    ) external;
}

interface ITradingStakePool {
    function punish(
        address from,
        address to,
        uint256 vol
    ) external;

    function stake(address account, uint256 amount) external;

    function withdraw(address account, uint256 amount) external;
}

interface IVault {
    function rebase() external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router01 {
    //function factory() external pure returns (address);
    function WETH() external pure returns (address);

    //function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract PlaceHolder {
    
}


/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback () payable external {
    _fallback();
  }
  
  receive () virtual payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() virtual internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() virtual internal {
      
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    if(OpenZeppelinUpgradesAddress.isContract(msg.sender) && msg.data.length == 0 && gasleft() <= 2300)         // for receive ETH only from other contract
        return;
    _willFallback();
    _delegate(_implementation());
  }
}


/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
abstract contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() virtual override internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(newImplementation == address(0) || OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}


/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() virtual override internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    //super._willFallback();
  }
}

interface IAdminUpgradeabilityProxyView {
  function admin() external view returns (address);
  function implementation() external view returns (address);
}


/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
abstract contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
  
  //function _willFallback() virtual override internal {
    //super._willFallback();
  //}
}


/**
 * @title AdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for 
 * initializing the implementation, admin, and init data.
 */
contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {
  /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, address _admin, bytes memory _data) UpgradeabilityProxy(_logic, _data) public payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
  
  function _willFallback() override(Proxy, BaseAdminUpgradeabilityProxy) internal {
    super._willFallback();
  }
}


/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract __BaseAdminUpgradeabilityProxy__ is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  //modifier ifAdmin() {
  //  if (msg.sender == _admin()) {
  //    _;
  //  } else {
  //    _fallback();
  //  }
  //}
  modifier ifAdmin() {
    require (msg.sender == _admin(), 'only admin');
      _;
  }

  /**
   * @return The address of the proxy admin.
   */
  //function admin() external ifAdmin returns (address) {
  //  return _admin();
  //}
  function __admin__() external view returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  //function implementation() external ifAdmin returns (address) {
  //  return _implementation();
  //}
  function __implementation__() external view returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  //function changeAdmin(address newAdmin) external ifAdmin {
  //  require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
  //  emit AdminChanged(_admin(), newAdmin);
  //  _setAdmin(newAdmin);
  //}
  function __changeAdmin__(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  //function upgradeTo(address newImplementation) external ifAdmin {
  //  _upgradeTo(newImplementation);
  //}
  function __upgradeTo__(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  //function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
  //  _upgradeTo(newImplementation);
  //  (bool success,) = newImplementation.delegatecall(data);
  //  require(success);
  //}
  function __upgradeToAndCall__(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  //function _willFallback() virtual override internal {
  //  require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
  //  //super._willFallback();
  //}
}


/**
 * @title AdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for 
 * initializing the implementation, admin, and init data.
 */
contract __AdminUpgradeabilityProxy__ is __BaseAdminUpgradeabilityProxy__, UpgradeabilityProxy {
  /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, address _admin, bytes memory _data) UpgradeabilityProxy(_logic, _data) public payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
  
  //function _willFallback() override(Proxy, BaseAdminUpgradeabilityProxy) internal {
  //  super._willFallback();
  //}
}  

contract __AdminUpgradeabilityProxy0__ is __BaseAdminUpgradeabilityProxy__, UpgradeabilityProxy {
  constructor() UpgradeabilityProxy(address(0), "") public {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(msg.sender);
  }
}


/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
abstract contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}


/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
  /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, address _admin, bytes memory _data) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(_logic, _data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
  
  function _willFallback() override(Proxy, BaseAdminUpgradeabilityProxy) internal {
    super._willFallback();
  }

}


interface IProxyFactory {
    function governor() external view returns (address);
    function __admin__() external view returns (address);
    function productImplementation() external view returns (address);
    function productImplementations(bytes32 name) external view returns (address);
}


/**
 * @title ProductProxy
 * @dev This contract implements a proxy that 
 * it is deploied by ProxyFactory, 
 * and it's implementation is stored in factory.
 */
contract ProductProxy is Proxy {
    
  /**
   * @dev Storage slot with the address of the ProxyFactory.
   * This is the keccak-256 hash of "eip1967.proxy.factory" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant FACTORY_SLOT = 0x7a45a402e4cb6e08ebc196f20f66d5d30e67285a2a8aa80503fa409e727a4af1;
  bytes32 internal constant NAME_SLOT    = 0x4cd9b827ca535ceb0880425d70eff88561ecdf04dc32fcf7ff3b15c587f8a870;      // bytes32(uint256(keccak256('eip1967.proxy.name')) - 1)

  function _name() virtual internal view returns (bytes32 name_) {
    bytes32 slot = NAME_SLOT;
    assembly {  name_ := sload(slot)  }
  }
  
  function _setName(bytes32 name_) internal {
    bytes32 slot = NAME_SLOT;
    assembly {  sstore(slot, name_)  }
  }

  /**
   * @dev Sets the factory address of the ProductProxy.
   * @param newFactory Address of the new factory.
   */
  function _setFactory(address newFactory) internal {
    require(newFactory == address(0) || OpenZeppelinUpgradesAddress.isContract(newFactory), "Cannot set a factory to a non-contract address");

    bytes32 slot = FACTORY_SLOT;

    assembly {
      sstore(slot, newFactory)
    }
  }

  /**
   * @dev Returns the factory.
   * @return factory_ Address of the factory.
   */
  function _factory() internal view returns (address factory_) {
    bytes32 slot = FACTORY_SLOT;
    assembly {
      factory_ := sload(slot)
    }
  }
  
  /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
  function _implementation() virtual override internal view returns (address) {
    address factory_ = _factory();
    bytes32 name_ = _name();
    if(OpenZeppelinUpgradesAddress.isContract(factory_))
        if(name_ != 0x0)
            return IProxyFactory(factory_).productImplementations(name_);
        else
            return IProxyFactory(factory_).productImplementation();
    else
        return address(0);
  }

}


/**
 * @title InitializableProductProxy
 * @dev Extends ProductProxy with an initializer for initializing
 * factory and init data.
 */
contract InitializableProductProxy is ProductProxy {
  /**
   * @dev Contract initializer.
   * @param factory Address of the initial factory.
   * @param data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function __InitializableProductProxy_init(address factory, bytes32 name, bytes memory data) external payable {
    address factory_ = _factory();
    require(factory_ == address(0) || msg.sender == factory_ || msg.sender == IProxyFactory(factory_).governor() || msg.sender == IProxyFactory(factory_).__admin__());
    assert(FACTORY_SLOT == bytes32(uint256(keccak256('eip1967.proxy.factory')) - 1));
    assert(NAME_SLOT    == bytes32(uint256(keccak256('eip1967.proxy.name')) - 1));
    _setFactory(factory);
    _setName(name);
    if(data.length > 0) {
      (bool success,) = _implementation().delegatecall(data);
      require(success);
    }
  }  
}


contract __InitializableAdminUpgradeabilityProductProxy__ is __BaseAdminUpgradeabilityProxy__, ProductProxy {
  function __InitializableAdminUpgradeabilityProductProxy_init__(address logic, address admin, address factory, bytes32 name, bytes memory data) public payable {
    assert(IMPLEMENTATION_SLOT  == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    assert(ADMIN_SLOT           == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    assert(FACTORY_SLOT         == bytes32(uint256(keccak256('eip1967.proxy.factory')) - 1));
    assert(NAME_SLOT            == bytes32(uint256(keccak256('eip1967.proxy.name')) - 1));
    address admin_ = _admin();
    require(admin_ == address(0) || msg.sender == admin_);
    _setAdmin(admin);
    _setImplementation(logic);
    _setFactory(factory);
    _setName(name);
    if(data.length > 0) {
      (bool success,) = _implementation().delegatecall(data);
      require(success);
    }
  }
  
  function _implementation() virtual override(BaseUpgradeabilityProxy, ProductProxy) internal view returns (address impl) {
    impl = ProductProxy._implementation();
    if(impl == address(0))
        impl = BaseUpgradeabilityProxy._implementation();
  }
}

contract __AdminUpgradeabilityProductProxy__ is __InitializableAdminUpgradeabilityProductProxy__ {
  constructor(address logic, address admin, address factory, bytes32 name, bytes memory data) public payable {
    __InitializableAdminUpgradeabilityProductProxy_init__(logic, admin, factory, name, data);
  }
}

contract __AdminUpgradeabilityProductProxy0__ is __InitializableAdminUpgradeabilityProductProxy__ {
  constructor() public {
    __InitializableAdminUpgradeabilityProductProxy_init__(address(0), msg.sender, address(0), 0, "");
  }
}


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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function sub0(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function div0(uint256 a, uint256 b) internal pure returns (uint256) {
        return b == 0 ? 0 : a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}

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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
contract ERC20UpgradeSafe is ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    uint256 internal _cap;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function __ERC20Capped_init(string memory name, string memory symbol, uint256 cap) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
		__ERC20Capped_init_unchained(cap);
    }

    function __ERC20Capped_init_unchained(uint256 cap) internal initializer {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() virtual public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        if(sender != _msgSender() && _allowances[sender][_msgSender()] != uint(-1))
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
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        if (_cap > 0) { // When Capped
            require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        }
		
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
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    function _setupDecimals(uint8 decimals_) internal {
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

    uint256[43] private __gap;
}


abstract contract Permit {		// ERC2612
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    function DOMAIN_SEPARATOR() virtual public view returns (bytes32);

    mapping (address => uint) public nonces;

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'permit EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'permit INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual;    

    uint256[49] private __gap;
}

contract ERC20Permit is ERC20UpgradeSafe, Permit {
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    
    function DOMAIN_SEPARATOR() virtual override public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), keccak256(bytes("1")), _chainId(), address(this)));
    }
    
    function _chainId() internal pure returns (uint id) {
        assembly { id := chainid() }
    }
    
    function _approve(address owner, address spender, uint256 amount) virtual override(Permit, ERC20UpgradeSafe) internal {
        return ERC20UpgradeSafe._approve(owner, spender, amount);
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
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

    function safeApprove_(IERC20 token, address spender, uint256 value) internal {
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
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract Governable is Initializable {
    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function __Governable_init_unchained(address governor_) virtual public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }
    
    modifier governance() {
        require(msg.sender == governor || msg.sender == _admin());
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }
}


contract Configurable is Governable {
    mapping (bytes32 => uint) internal config;
    
    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfigI(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfigA(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }

    function setConfig(bytes32 key, uint value) external governance {
        _setConfig(key, value);
    }
    function setConfigI(bytes32 key, uint index, uint value) external governance {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfigA(bytes32 key, address addr, uint value) public governance {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";
import "./Mining.sol";

struct Merchant {
    //uint    id;
    address account;
    bool isMerchant;
    //uint    merchantMargin;
}

contract MerchantStakePool is StakingPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 internal constant _DOTC_ = "DOTC";

    address public dotcAddr;

    mapping(address => string) public links; //tg link
    mapping(uint256 => Merchant) public merchants; //id =>Merchant  id from 1...
    mapping(address => uint256) public merchantIds; //address =>id
    uint256 public maxMerchantID;
    uint256 public merchantCount;

    function __MerchantStakePool_init(
        address _governor,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _ecoAddr,
        address _dotcAddr
    ) public initializer {
        if (_rewardsDistribution == address(this)) {
            require(
                _rewardsToken != _stakingToken,
                "reward must diff stakingtoken"
            );
        }
        __ReentrancyGuard_init_unchained();
        __Governable_init_unchained(_governor);
        __StakingPool_init_unchained(
            _rewardsDistribution,
            _rewardsToken,
            _stakingToken,
            _ecoAddr
        );
        __MerchantStakePool_init_unchained(_dotcAddr);
    }

    function __MerchantStakePool_init_unchained(address _dotcAddr)
        internal
        governance
        initializer
    {
        dotcAddr = _dotcAddr;
    }

    function setPara(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _ecoAddr
    ) public virtual governance {
        __StakingPool_init_unchained(
            _rewardsDistribution,
            _rewardsToken,
            _stakingToken,
            _ecoAddr
        );
    }

    function punish(
        address from,
        address to,
        uint256 vol
    ) external virtual updateReward(from) updateReward(to) {
        require(msg.sender == dotcAddr, "only DOTC");
        uint256 amt = _balances[from];
        require(amt >= vol, "stake must GT punish vol");
        _balances[from] = amt.sub(vol);
        //_balances[to] = _balances[to].add(vol);
        stakingToken.safeTransfer(to, vol);
        emit Punish(from, to, vol);
    }

    event Punish(address from, address to, uint256 amt);

    function stake(uint256 amount) public virtual override {
        require(isMerchant(msg.sender), "only Merchant");
        super.stake(amount);
    }

    function withdraw(uint256 amount) public virtual override {
        require(!isMerchant(msg.sender), "Merchant can't withdraw");
        super.withdraw(amount);
    }

    function isMerchant(address account) public view returns (bool) {
        bool ret = false;
        uint256 id = merchantIds[account];
        if (id > 0) ret = merchants[id].isMerchant;
        return ret;
    }

    function addMerchant_(address[] calldata account_, string[] calldata links_)
        external
        governance
    {
        uint256 maxID = maxMerchantID;
        uint256 count = 0;
        uint256 curID;
        //Merchant memory merchant;
        for (uint256 i = 0; i < account_.length; i++) {
            if (merchantIds[account_[i]] == 0) {
                maxID++;
                curID = maxID;
                merchantIds[account_[i]] = curID;
                count++;
            } else {
                curID = merchantIds[account_[i]];
                if (!merchants[curID].isMerchant) {
                    count++;
                }
            }
            merchants[curID] = Merchant(account_[i], true);
            links[account_[i]] = links_[i];
        }
        if (maxID != maxMerchantID) maxMerchantID = maxID;
        merchantCount = merchantCount.add(count);
        emit AddMerchant(account_, links_);
    }

    event AddMerchant(address[] account, string[] links);

    function delMerchant_(address[] calldata account_) external governance {
        uint256 curID;
        uint256 count = 0;
        for (uint256 i = 0; i < account_.length; i++) {
            curID = merchantIds[account_[i]];
            if (curID > 0) {
                if (merchants[curID].isMerchant) {
                    merchants[curID].isMerchant = false;
                    count++;
                }
            }
        }
        merchantCount = merchantCount.sub(count);
        emit DelMerchant(account_);
    }

    event DelMerchant(address[] account);

    // Reserved storage space to allow for layout changes in the future.
    uint256[45] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

// Inheritancea
interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewards(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

abstract contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) virtual external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
}

contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuardUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish;// = 0;
    uint256 public rewardRate;// = 0;                  // obsoleted
    uint256 public rewardsDuration;// = 60 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) override public rewards;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    /* ========== CONSTRUCTOR ========== */

    //constructor(
    function __StakingRewards_init(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public virtual initializer {
        __ReentrancyGuard_init_unchained();
        __StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
    }

    function __StakingRewards_init_unchained(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) internal virtual initializer {
        if (_rewardsDistribution == address(this)){
            require(_rewardsToken!=_stakingToken,"reward must diff stakingtoken");
        }
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    function totalSupply() virtual override public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) virtual override public view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() override public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() virtual override public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) virtual override public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() virtual override external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) virtual internal nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        uint preAmount = stakingToken.balanceOf(address(this));
        IPermit(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint afterAmount = stakingToken.balanceOf(address(this));
        uint realAmount = afterAmount.sub(preAmount);
        _totalSupply = _totalSupply.add(realAmount);
        _balances[msg.sender] = _balances[msg.sender].add(realAmount);
        emit Staked(msg.sender, realAmount);
    }

    function stake(uint256 amount) virtual override public {
        _stakeTo(amount, msg.sender);
    }
    function _stakeTo(uint256 amount, address to) virtual internal nonReentrant updateReward(to) {
        require(amount > 0, "Cannot stake 0");
        uint preAmount = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint afterAmount = stakingToken.balanceOf(address(this));
        uint realAmount = afterAmount.sub(preAmount);
        _totalSupply = _totalSupply.add(realAmount);
        _balances[to] = _balances[to].add(realAmount);
        emit Staked(to, realAmount);
    }

    function withdraw(uint256 amount) virtual override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }




    function getReward() virtual override public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() virtual override public {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) override external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) virtual {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

interface IPermit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract StakingPool is Configurable, StakingRewards {
    using Address for address payable;
    
    bytes32 internal constant _ecoAddr_         = 'ecoAddr';
    bytes32 internal constant _ecoRatio_        = 'ecoRatio';
	bytes32 internal constant _allowContract_   = 'allowContract';
	bytes32 internal constant _allowlist_       = 'allowlist';
	bytes32 internal constant _blocklist_       = 'blocklist';
	
	bytes32 internal constant _rewards2Token_   = 'rewards2Token';
	bytes32 internal constant _rewards2Ratio_   = 'rewards2Ratio';
	//bytes32 internal constant _rewards2Span_    = 'rewards2Span';
	bytes32 internal constant _rewards2Begin_   = 'rewards2Begin';

	uint public lep;            // 1: linear, 2: exponential, 3: power
	//uint public period;         // obsolete
	uint public begin;

    mapping (address => uint256) public paid;
    
    address swapFactory;
    address[] pathTVL;
    address[] pathAPR;

    function __StakingPool_init(address _governor, 
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _ecoAddr
    ) public virtual initializer {
	    __ReentrancyGuard_init_unchained();
	    __Governable_init_unchained(_governor);
        //__StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken, _ecoAddr);
    }

    function __StakingPool_init_unchained(address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr) internal virtual governance {
        if (_rewardsDistribution == address(this)){
            require(_rewardsToken!=_stakingToken,"reward must diff stakingtoken");
        }
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        config[_ecoAddr_] = uint(_ecoAddr);
        config[_ecoRatio_] = 0.1 ether;
    }

    function notifyRewardBegin(uint _lep, /*uint _period,*/ uint _span, uint _begin) virtual public governance updateReward(address(0)) {
        lep             = _lep;         // 1: linear, 2: exponential, 3: power
        //period          = _period;
        rewardsDuration = _span;
        begin           = _begin;
        periodFinish    = _begin.add(_span);
    }
    
    function notifyReward2(address _rewards2Token, uint _ratio, /*uint _span,*/ uint _begin) virtual external governance updateReward(address(0)) {
        config[_rewards2Token_] = uint(_rewards2Token);
        config[_rewards2Ratio_] = _ratio;
        //config[_rewards2Span_]  = _span;
        config[_rewards2Begin_] = _begin;
    }

    function _rewardDelta() internal view returns (uint amt) {
        if(begin == 0 || begin >= now || lastUpdateTime >= now)
            return 0;
            
        amt = Math.min(rewardsToken.allowance(rewardsDistribution, address(this)), rewardsToken.balanceOf(rewardsDistribution)).sub0(rewards[address(0)]);
        
        // calc rewardDelta in period
        if(lep == 3) {                                                              // power
            //uint y = period.mul(1 ether).div(lastUpdateTime.add(rewardsDuration).sub(begin));
            //uint amt1 = amt.mul(1 ether).div(y);
            //uint amt2 = amt1.mul(period).div(now.add(rewardsDuration).sub(begin));
            uint amt2 = amt.mul(lastUpdateTime.add(rewardsDuration).sub(begin)).div(now.add(rewardsDuration).sub(begin));
            amt = amt.sub(amt2);
        } else if(lep == 2) {                                                       // exponential
            if(now.sub(lastUpdateTime) < rewardsDuration)
                amt = amt.mul(now.sub(lastUpdateTime)).div(rewardsDuration);
        }else if(now < periodFinish)                                                // linear
            amt = amt.mul(now.sub(lastUpdateTime)).div(periodFinish.sub(lastUpdateTime));
        else if(lastUpdateTime >= periodFinish)
            amt = 0;
    }            

    function rewardDelta() public view returns (uint amt) {
        amt = _rewardDelta();
        if(config[_ecoAddr_] != 0)
            amt = amt.mul(uint(1e18).sub(config[_ecoRatio_])).div(1 ether);
    }
    
    function rewardPerToken() virtual override public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                rewardDelta().mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) virtual override public view returns (uint256) {
        return Math.min(Math.min(super.earned(account), rewardsToken.allowance(rewardsDistribution, address(this))), rewardsToken.balanceOf(rewardsDistribution));
	}    
	
    modifier updateReward(address account) virtual override {
        rewardPerTokenStored = rewardPerToken();
        uint delta = rewardDelta();
        {
            address addr = address(config[_ecoAddr_]);
            uint ratio = config[_ecoRatio_];
            if(addr != address(0) && ratio != 0) {
                uint d = delta.mul(ratio).div(uint(1e18).sub(ratio));
                rewards[addr] = rewards[addr].add(d);
                delta = delta.add(d);
            }
        }
        rewards[address(0)] = rewards[address(0)].add(delta);
        lastUpdateTime = now;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function getReward() virtual override public {
        getRewardA(msg.sender);
    }
    function getRewardA(address payable acct) virtual public nonReentrant updateReward(acct) {
        require(getConfigA(_blocklist_, acct) == 0, 'In blocklist');
        bool isContract = acct.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfigA(_allowlist_, acct) != 0, 'No allowContract');

        uint256 reward = rewards[acct];
        if (reward > 0) {
            rewards[acct] = 0;
            rewards[address(0)] = rewards[address(0)].sub0(reward);
            rewardsToken.safeTransferFrom(rewardsDistribution, acct, reward);
            emit RewardPaid(acct, reward);
            
            if(config[_rewards2Token_] != 0 && config[_rewards2Begin_] <= now) {
                uint reward2 = Math.min(reward.mul(config[_rewards2Ratio_]).div(1e18), IERC20(config[_rewards2Token_]).balanceOf(address(this)));
                IERC20(config[_rewards2Token_]).safeTransfer(acct, reward2);
                emit RewardPaid2(acct, reward2);
            }
        }
    }
    event RewardPaid2(address indexed user, uint256 reward2);

    function compound() virtual public nonReentrant updateReward(msg.sender) {      // only for pool3
        require(getConfigA(_blocklist_, msg.sender) == 0, 'In blocklist');
        bool isContract = msg.sender.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfigA(_allowlist_, msg.sender) != 0, 'No allowContract');
        require(stakingToken == rewardsToken, 'not pool3');
    
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewards[address(0)] = rewards[address(0)].sub0(reward);
            rewardsToken.safeTransferFrom(rewardsDistribution, address(this), reward);
            emit RewardPaid(msg.sender, reward);
            
            _totalSupply = _totalSupply.add(reward);
            _balances[msg.sender] = _balances[msg.sender].add(reward);
            emit Staked(msg.sender, reward);
        }
    }

    function getRewardForDuration() override external view returns (uint256) {
        return rewardsToken.allowance(rewardsDistribution, address(this)).sub0(rewards[address(0)]);
    }
    
    function rewards2Token() virtual external view returns (address) {
        return address(config[_rewards2Token_]);
    }
    
    function rewards2Ratio() virtual external view returns (uint) {
        return config[_rewards2Ratio_];
    }
    
    function setPath(address swapFactory_, address[] memory pathTVL_, address[] memory pathAPR_) virtual external governance {
        uint m = pathTVL_.length;
        uint n = pathAPR_.length;
        require(m > 0 && n > 0 && pathTVL_[m-1] == pathAPR_[n-1]);
        for(uint i=0; i<m-1; i++)
            require(address(0) != IUniswapV2Factory(swapFactory_).getPair(pathTVL_[i], pathTVL_[i+1]));
        for(uint i=0; i<n-1; i++)
            require(address(0) != IUniswapV2Factory(swapFactory_).getPair(pathAPR_[i], pathAPR_[i+1]));
            
        swapFactory = swapFactory_;
        pathTVL = pathTVL_;
        pathAPR = pathAPR_;
    }
    
    function lptValueTotal() virtual public view returns (uint) {
        require(pathTVL.length > 0 && pathTVL[0] != address(stakingToken));
        return IERC20(pathTVL[0]).balanceOf(address(stakingToken)).mul(2);
    }
    
    function lptValue(uint vol) virtual public view returns (uint) {
        return lptValueTotal().mul(vol).div(IERC20(stakingToken).totalSupply());
    }
    
    function swapValue(uint vol, address[] memory path) virtual public view returns (uint v) {
        v = vol;
        for(uint i=0; i<path.length-1; i++) {
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(IUniswapV2Factory(swapFactory).getPair(path[i], path[i+1])).getReserves();
            v =  path[i+1] < path[i] ? v.mul(reserve0) / reserve1 : v.mul(reserve1) / reserve0;
        }
    }
    
    function TVL() virtual public view returns (uint tvl) {
        if(pathTVL[0] != address(stakingToken))
            tvl = lptValueTotal();
        else
            tvl = totalSupply();
        tvl = swapValue(tvl, pathTVL);
    }
    
    function APR() virtual public view returns (uint) {
        uint amt = rewardsToken.allowance(rewardsDistribution, address(this)).sub0(rewards[address(0)]);
        
        if(lep == 3) {                                                              // power
            uint amt2 = amt.mul(now.add(rewardsDuration).sub(begin)).div(now.add(1).add(rewardsDuration).sub(begin));
            amt = amt.sub(amt2).mul(365 days);
        } else if(lep == 2) {                                                       // exponential
            amt = amt.mul(365 days).div(rewardsDuration);
        }else if(now < periodFinish)                                                // linear
            amt = amt.mul(365 days).div(periodFinish.sub(lastUpdateTime));
        else if(lastUpdateTime >= periodFinish)
            amt = 0;
        
        require(address(rewardsToken) == pathAPR[0]);
        amt = swapValue(amt, pathAPR);
        return amt.mul(1e18).div(TVL());
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract EthPool is StakingPool {
    bytes32 internal constant _WETH_			= 'WETH';

    function __EthPool_init(address _governor, 
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _ecoAddr,
		address _WETH
    ) public virtual initializer {
	    __ReentrancyGuard_init_unchained();
	    __Governable_init_unchained(_governor);
        //__StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken, _ecoAddr);
		__EthPool_init_unchained(_WETH);
    }

    function __EthPool_init_unchained(address _WETH) internal virtual governance {
        config[_WETH_] = uint(_WETH);
    }

    function stakeEth() virtual public payable nonReentrant updateReward(msg.sender) {
        require(address(stakingToken) == address(config[_WETH_]), 'stakingToken is not WETH');
        uint amount = msg.value;
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IWETH(address(stakingToken)).deposit{value: amount}();                   //stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdrawEth(uint256 amount) virtual public nonReentrant updateReward(msg.sender) {
        require(address(stakingToken) == address(config[_WETH_]), 'stakingToken is not WETH');
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IWETH(address(stakingToken)).withdraw(amount);                           //stakingToken.safeTransfer(msg.sender, amount);
        msg.sender.transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exitEth() virtual public {
        withdrawEth(_balances[msg.sender]);
        getReward();
    }
    
    receive () payable external {
        stakeEth();
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

contract DoublePool is StakingPool {
    IStakingRewards public stakingPool2;
    IERC20 public rewardsToken2;
    //uint256 public lastUpdateTime2;                                 // obsoleted
    //uint256 public rewardPerTokenStored2;                           // obsoleted
    mapping(address => uint256) public userRewardPerTokenPaid2;
    mapping(address => uint256) public rewards2;

    function __DoublePool_init(address _governor, address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr, address _stakingPool2, address _rewardsToken2) public initializer {
        if (_rewardsDistribution == address(this)){
            require(_rewardsToken!=_stakingToken,"reward must diff stakingtoken");
            require(_rewardsToken2!=_stakingToken,"reward token2 must diff stakingtoken");
        }

	    __ReentrancyGuard_init_unchained();
	    __Governable_init_unchained(_governor);
	    //__StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
	    __StakingPool_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken, _ecoAddr);
	    __DoublePool_init_unchained(_stakingPool2, _rewardsToken2);
	}
    
    function __DoublePool_init_unchained(address _stakingPool2, address _rewardsToken2) internal governance initializer{
	    stakingPool2 = IStakingRewards(_stakingPool2);
	    rewardsToken2 = IERC20(_rewardsToken2);
	}
    
    function notifyRewardBegin(uint _lep, /*uint _period,*/ uint _span, uint _begin) virtual override public governance updateReward2(address(0)) {
        super.notifyRewardBegin(_lep, /*_period,*/ _span, _begin);
    }
    
    function stake(uint amount) virtual override public updateReward2(msg.sender) {
        super.stake(amount);
        stakingToken.safeApprove(address(stakingPool2), amount);
        stakingPool2.stake(amount);
    }

    function withdraw(uint amount) virtual override public updateReward2(msg.sender) {
        stakingPool2.withdraw(amount);
        super.withdraw(amount);
    }
    
    function getReward2() virtual public nonReentrant updateReward2(msg.sender) {
        uint256 reward2 = rewards2[msg.sender];
        if (reward2 > 0) {
            rewards2[msg.sender] = 0;
            stakingPool2.getReward();
            rewardsToken2.safeTransfer(msg.sender, reward2);
            emit RewardPaid2(msg.sender, reward2);
        }
    }
    event RewardPaid2(address indexed user, uint256 reward2);

    function getDoubleReward() virtual public {
        getReward();
        getReward2();
    }
    
    function exit() override virtual public {
        super.exit();
        getReward2();
    }
    
    function rewardPerToken2() virtual public view returns (uint256) {
        return stakingPool2.rewardPerToken();
    }

    function earned2(address account) virtual public view returns (uint256) {
        return _balances[account].mul(rewardPerToken2().sub(userRewardPerTokenPaid2[account])).div(1e18).add(rewards2[account]);
    }

    modifier updateReward2(address account) virtual {
        if (account != address(0)) {
            rewards2[account] = earned2(account);
            userRewardPerTokenPaid2[account] = rewardPerToken2();
        }
        _;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}



contract DoublePoolNestChef is DoublePool {  //double pool nest a nestMastchef
    IERC20 public rewardsToken3;  //cake
    mapping(address => uint256) public userRewardPerTokenPaid3;
    mapping(address => uint256) public rewards3;

    function __DoublePoolNestChef_init(address _governor, address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr, address _stakingPool2, address _rewardsToken2,address _rewardsToken3) public initializer {
        super.__DoublePool_init(_governor, _rewardsDistribution, _rewardsToken, _stakingToken,  _ecoAddr, _stakingPool2, _rewardsToken2);
        __DoublePoolNestChef_init_unchained(_stakingPool2, _rewardsToken2,_rewardsToken3);
	}

    function __DoublePoolNestChef_init_unchained(address _stakingPool2, address _rewardsToken2,address _rewardsToken3) internal governance {
        setPara(_stakingPool2, _rewardsToken2, _rewardsToken3);
	}

    function setPara(address _stakingPool2, address _rewardsToken2,address _rewardsToken3) public governance {
        if (rewardsDistribution == address(this)){
            require(rewardsToken!=stakingToken,"reward must diff stakingtoken");
            require(_rewardsToken2!=address(stakingToken),"reward token2 must diff stakingtoken");
            require(_rewardsToken3!=address(stakingToken),"reward token3 must diff stakingtoken");
        }
	    stakingPool2 = IStakingRewards(_stakingPool2);
	    rewardsToken2 = IERC20(_rewardsToken2);
        rewardsToken3 = IERC20(_rewardsToken3);
	}


    function notifyRewardBegin(uint _lep, /*uint _period,*/ uint _span, uint _begin) virtual override public updateReward3(address(0)) {
        super.notifyRewardBegin(_lep, /*_period,*/ _span, _begin);
    }
    
    function stake(uint amount) virtual override public updateReward3(msg.sender) {
        super.stake(amount);
    }

    function withdraw(uint amount) virtual override public updateReward3(msg.sender) {
        super.withdraw(amount);
    }

    function getReward3() virtual public nonReentrant updateReward3(msg.sender) {
        uint256 reward3 = rewards3[msg.sender];
        if (reward3 > 0) {
            rewards3[msg.sender] = 0;
            NestMasterChef(address(stakingPool2)).getReward2();
            rewardsToken3.safeTransfer(msg.sender, reward3);
            emit RewardPaid3(msg.sender, reward3);
        }
    }
    event RewardPaid3(address indexed user, uint256 reward3);

    function getRewardAll()  virtual public{
        getReward2();
        getReward3();
    } 
    
    function exit() override public {
        super.exit();
        getRewardAll();
    }
    
    function rewardPerToken3() virtual public view returns (uint256) {
        return NestMasterChef(address(stakingPool2)).rewardPerToken2();
    }

    function earned3(address account) virtual public view returns (uint256) {
        return _balances[account].mul(rewardPerToken3().sub(userRewardPerTokenPaid3[account])).div(1e18).add(rewards3[account]);
    }

    modifier updateReward3(address account) virtual {
        if (account != address(0)) {
            rewards3[account] = earned3(account);
            userRewardPerTokenPaid3[account] = rewardPerToken3();
        }
        _;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}



interface IMasterChef {
    function poolInfo(uint pid) external view returns (address lpToken, uint allocPoint, uint lastRewardBlock, uint accCakePerShare);
    function userInfo(uint pid, address user) external view returns (uint amount, uint rewardDebt);
    function pending(uint pid, address user) external view returns (uint);
    function pendingCake(uint pid, address user) external view returns (uint);
    function deposit(uint pid, uint amount) external;
    function withdraw(uint pid, uint amount) external;
}

contract NestMasterChef is StakingPool {
    using Address for address;
    IERC20 internal constant Cake = IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    
    IMasterChef public stakingPool2;
    IERC20 public rewardsToken2;
    mapping(address => uint256) public userRewardPerTokenPaid2;
    mapping(address => uint256) public rewards2;
    uint public pid2;
    uint internal _rewardPerToken2;

    function __NestMasterChef_init(address _governor, address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr, address _stakingPool2, address _rewardsToken2, uint _pid2) public initializer {
        if (_rewardsDistribution == address(this)){
            require(_rewardsToken!=_stakingToken,"reward must diff stakingtoken");
            require(_rewardsToken2!=_stakingToken,"reward token2 must diff stakingtoken");
        }
	    __Governable_init_unchained(_governor);
        __ReentrancyGuard_init_unchained();
        //__StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken, _ecoAddr);
        __NestMasterChef_init_unchained(_stakingPool2, _rewardsToken2, _pid2);
	}

    function __NestMasterChef_init_unchained(address _stakingPool2, address _rewardsToken2, uint _pid2) internal governance {
	    stakingPool2 = IMasterChef(_stakingPool2);
	    rewardsToken2 = IERC20(_rewardsToken2);
	    pid2 = _pid2;
    }

    function __NestMasterChef_init_unchained_migrate(address _stakingPool2, address _rewardsToken2, uint _pid2) public governance {
	    stakingPool2 = IMasterChef(_stakingPool2);
	    rewardsToken2 = IERC20(_rewardsToken2);
	    pid2 = _pid2;
        migrate();
    }
    
    
    function notifyRewardBegin(uint _lep, /*uint _period,*/ uint _span, uint _begin) virtual override public governance updateReward2(address(0)) {
        super.notifyRewardBegin(_lep, /*_period,*/ _span, _begin);
    }

    function migratePancakeV2(address pancakeV2,uint pidV2) virtual public governance updateReward2(address(0)) {
        bool isContract = pancakeV2.isContract();
        require(isContract,"Not contract");
        (uint amount,) = stakingPool2.userInfo(pid2,address(this));
        stakingPool2.withdraw(pid2, amount);
        stakingToken.approve(pancakeV2, amount);
        stakingPool2 = IMasterChef(pancakeV2);
        pid2 = pidV2;
        stakingPool2.deposit(pidV2, amount);
    }   
    
    function migrate() virtual public governance updateReward2(address(0)) {
        uint total = stakingToken.balanceOf(address(this));
        stakingToken.approve(address(stakingPool2), total);
        stakingPool2.deposit(pid2, total);
    }        
    
    function stake(uint amount) virtual override public updateReward2(msg.sender) {
        super.stake(amount);
        stakingToken.approve(address(stakingPool2), amount);
        stakingPool2.deposit(pid2, amount);
    }

    function withdraw(uint amount) virtual override public updateReward2(msg.sender) {
        stakingPool2.withdraw(pid2, amount);
        super.withdraw(amount);
    }
    
    function getReward2() virtual public nonReentrant updateReward2(msg.sender) {
        uint256 reward2 = rewards2[msg.sender];
        if (reward2 > 0) {
            rewards2[msg.sender] = 0;
            rewardsToken2.safeTransfer(msg.sender, reward2);
            emit RewardPaid2(msg.sender, reward2);
        }
    }
    event RewardPaid2(address indexed user, uint256 reward2);

    function getDoubleReward() virtual public {
        getReward();
        getReward2();
    }
    
    function exit() virtual override public {
        super.exit();
        getReward2();
    }
    
    function rewardPerToken2() virtual public view returns (uint256) {
        if(_totalSupply == 0)
            return _rewardPerToken2;
        else if(rewardsToken2 == Cake)
            return stakingPool2.pendingCake(pid2, address(this)).mul(1e18).div(_totalSupply).add(_rewardPerToken2);
        else
            return stakingPool2.pending(pid2, address(this)).mul(1e18).div(_totalSupply).add(_rewardPerToken2);
    }

    function earned2(address account) virtual public view returns (uint256) {
        return _balances[account].mul(rewardPerToken2().sub(userRewardPerTokenPaid2[account])).div(1e18).add(rewards2[account]);
    }

    modifier updateReward2(address account) virtual {
        if(_totalSupply > 0) {
            uint delta = rewardsToken2.balanceOf(address(this));
            stakingPool2.deposit(pid2, 0);
            delta = rewardsToken2.balanceOf(address(this)).sub(delta);
            _rewardPerToken2 = delta.mul(1e18).div(_totalSupply).add(_rewardPerToken2);
        }
        
        if (account != address(0)) {
            rewards2[account] = earned2(account);
            userRewardPerTokenPaid2[account] = _rewardPerToken2;
        }
        _;
    }

    uint256[50] private __gap;
}

contract IioPoolV2 is StakingPool {         // support multi IIO at the same time
    //address internal constant HelmetAddress = 0x948d2a81086A075b3130BAc19e4c6DEe1D2E3fE8;
    address internal constant BurnAddress   = 0x000000000000000000000000000000000000dEaD;

    uint private __lastUpdateTime3;                             // obsolete
    IERC20 private __rewardsToken3;                             // obsolete
    mapping(IERC20 => uint) public totalSupply3;                                    // rewardsToken3 => totalSupply3
    mapping(IERC20 => uint) internal _rewardPerToken3;                              // rewardsToken3 => _rewardPerToken3
    mapping(IERC20 => uint) public begin3;                                          // rewardsToken3 => begin3
    mapping(IERC20 => uint) public end3;                                            // rewardsToken3 => end3
    mapping(IERC20 => uint) public claimTime3;                                      // rewardsToken3 => claimTime3
    mapping(IERC20 => uint) public ticketVol3;                                      // rewardsToken3 => ticketVol3
    mapping(IERC20 => IERC20)  public ticketToken3;                                 // rewardsToken3 => ticketToken3
    mapping(IERC20 => address) public ticketRecipient3;                             // rewardsToken3 => ticketRecipient3

    mapping(IERC20 => mapping(address => bool)) public applied3;                    // rewardsToken3 => acct => applied3
    mapping(IERC20 => mapping(address => uint)) public userRewardPerTokenPaid3;     // rewardsToken3 => acct => paid3
    mapping(IERC20 => mapping(address => uint)) public rewards3;                    // rewardsToken3 => acct => rewards3
    
    mapping(IERC20 => uint) public lastUpdateTime3;                                 // rewardsToken3 => lastUpdateTime3
    IERC20[] public all;                                                            // all rewardsToken3
    IERC20[] public active;                                                         // active rewardsToken3
    
    //function setReward3BurnHelmet(IERC20 rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_) virtual external {
    //    setReward3(rewardsToken3_, begin3_, end3_, claimTime3_, ticketVol3_, IERC20(HelmetAddress), BurnAddress);
    //}
    function setReward3(IERC20 rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_, IERC20 ticketToken3_, address ticketRecipient3_) virtual public governance {
        lastUpdateTime3     [rewardsToken3_]= begin3_;
        //rewardsToken3       = rewardsToken3_;
        begin3              [rewardsToken3_] = begin3_;
        end3                [rewardsToken3_] = end3_;
        claimTime3          [rewardsToken3_] = claimTime3_;
        ticketVol3          [rewardsToken3_] = ticketVol3_;
        ticketToken3        [rewardsToken3_] = ticketToken3_;
        ticketRecipient3    [rewardsToken3_] = ticketRecipient3_;
        
        uint i=0;
        for(; i<all.length; i++)
            if(all[i] == rewardsToken3_)
                break;
        if(i>=all.length)
            all.push(rewardsToken3_);
            
        i=0;
        for(; i<active.length; i++)
            if(active[i] == rewardsToken3_)
                break;
        if(i>=active.length)
            active.push(rewardsToken3_);
            
        emit SetReward3(rewardsToken3_, begin3_, end3_, claimTime3_, ticketVol3_, ticketToken3_, ticketRecipient3_);
    }
    event SetReward3(IERC20 indexed rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_, IERC20 indexed ticketToken3_, address indexed ticketRecipient3_);
    
    //function deactive(IERC20 rewardsToken3_) virtual public governance {
    //    for(uint i=0; i<active.length; i++)
    //        if(active[i] == rewardsToken3_) {
    //            active[i] = active[active.length-1];
    //            active.pop();
    //            emit Deactive(rewardsToken3_);
    //            return;
    //        }
    //    revert('not found active rewardsToken3_');
    //}
    //event Deactive(IERC20 indexed rewardsToken3_);

    function applyReward3(IERC20 rewardsToken3_) virtual public updateReward3(rewardsToken3_, msg.sender) {
        //IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        require(!applied3[rewardsToken3_][msg.sender], 'applied already');
        require(now < end3[rewardsToken3_], 'expired');
        
        IERC20 ticketToken3_ = ticketToken3[rewardsToken3_];                            // save gas
        if(address(ticketToken3_) != address(0))
            ticketToken3_.safeTransferFrom(msg.sender, ticketRecipient3[rewardsToken3_], ticketVol3[rewardsToken3_]);
        applied3[rewardsToken3_][msg.sender] = true;
        userRewardPerTokenPaid3[rewardsToken3_][msg.sender] = _rewardPerToken3[rewardsToken3_];
        totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].add(_balances[msg.sender]);
        emit ApplyReward3(msg.sender, rewardsToken3_);
    }
    event ApplyReward3(address indexed acct, IERC20 indexed rewardsToken3);
    
    function rewardDelta3(IERC20 rewardsToken3_) virtual public view returns (uint amt) {
        //IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        uint lastUpdateTime3_ = lastUpdateTime3[rewardsToken3_];                        // save gas
        if(begin3[rewardsToken3_] == 0 || begin3[rewardsToken3_] >= now || lastUpdateTime3_ >= now)
            return 0;
            
        amt = Math.min(rewardsToken3_.allowance(rewardsDistribution, address(this)), rewardsToken3_.balanceOf(rewardsDistribution)).sub0(rewards3[rewardsToken3_][address(0)]);
        
        uint end3_ = end3[rewardsToken3_];                                              // save gas
        if(now < end3_)
            amt = amt.mul(now.sub(lastUpdateTime3_)).div(end3_.sub(lastUpdateTime3_));
        else if(lastUpdateTime3_ >= end3_)
            amt = 0;
            
        if(config[_ecoAddr_] != 0)
            amt = amt.mul(uint(1e18).sub(config[_ecoRatio_])).div(1 ether);
    }
    
    function rewardPerToken3(IERC20 rewardsToken3_) virtual public view returns (uint) {
        if (totalSupply3[rewardsToken3_] == 0) {
            return _rewardPerToken3[rewardsToken3_];
        }
        return
            _rewardPerToken3[rewardsToken3_].add(
                rewardDelta3(rewardsToken3_).mul(1e18).div(totalSupply3[rewardsToken3_])
            );
    }

    function earned3(IERC20 rewardsToken3_, address account) virtual public view returns (uint) {
        if(!applied3[rewardsToken3_][account])
            return 0;
        return Math.min(rewardsToken3_.balanceOf(rewardsDistribution), _balances[account].mul(rewardPerToken3(rewardsToken3_).sub(userRewardPerTokenPaid3[rewardsToken3_][account])).div(1e18).add(rewards3[rewardsToken3_][account]));
    }

    function _updateReward3(IERC20 rewardsToken3_, address account) virtual internal {
        bool applied3_ = applied3[rewardsToken3_][account];                             // save gas
        if(account == address(0) || applied3_) {
            _rewardPerToken3[rewardsToken3_] = rewardPerToken3(rewardsToken3_);
            uint delta = rewardDelta3(rewardsToken3_);
            {
                address addr = address(config[_ecoAddr_]);
                uint ratio = config[_ecoRatio_];
                if(addr != address(0) && ratio != 0) {
                    uint d = delta.mul(ratio).div(uint(1e18).sub(ratio));
                    rewards3[rewardsToken3_][addr] = rewards3[rewardsToken3_][addr].add(d);
                    delta = delta.add(d);
                }
            }
            rewards3[rewardsToken3_][address(0)] = rewards3[rewardsToken3_][address(0)].add(delta);
            lastUpdateTime3[rewardsToken3_] = Math.max(begin3[rewardsToken3_], Math.min(now, end3[rewardsToken3_]));
        }
        if (account != address(0) && applied3_) {
            rewards3[rewardsToken3_][account] = earned3(rewardsToken3_, account);
            userRewardPerTokenPaid3[rewardsToken3_][account] = _rewardPerToken3[rewardsToken3_];
        }
    }
    
    modifier updateReward3(IERC20 rewardsToken3_, address account) virtual {
        _updateReward3(rewardsToken3_, account);
        _;
    }

    function stake(uint amount) virtual override public {
        super.stake(amount);
        for(uint i=0; i<active.length; i++) {
            IERC20 rewardsToken3_ = active[i];                                          // save gas
            _updateReward3(rewardsToken3_, msg.sender);
            if(applied3[rewardsToken3_][msg.sender])
                totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].add(amount);
        }    
    }

    function withdraw(uint amount) virtual override public {
        for(uint i=0; i<active.length; i++) {
            IERC20 rewardsToken3_ = active[i];                                          // save gas
            _updateReward3(rewardsToken3_, msg.sender);
            if(applied3[rewardsToken3_][msg.sender])
                totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].sub(amount);
        }
        super.withdraw(amount);
    }
    
    function getReward3(IERC20 rewardsToken3_) virtual public nonReentrant updateReward3(rewardsToken3_, msg.sender) {
        require(getConfigA(_blocklist_, msg.sender) == 0, 'In blocklist');
        bool isContract = msg.sender.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfigA(_allowlist_, msg.sender) != 0, 'No allowContract');

        //IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        require(now >= claimTime3[rewardsToken3_], "it's not time yet");
        uint256 reward3 = rewards3[rewardsToken3_][msg.sender];
        if (reward3 > 0) {
            rewards3[rewardsToken3_][msg.sender] = 0;
            rewards3[rewardsToken3_][address(0)] = rewards3[rewardsToken3_][address(0)].sub0(reward3);
            rewardsToken3_.safeTransferFrom(rewardsDistribution, msg.sender, reward3);
            emit RewardPaid3(msg.sender, rewardsToken3_, reward3);
        }
    }
    event RewardPaid3(address indexed user, IERC20 indexed rewardsToken3_, uint256 reward3);
    
    uint[47] private __gap;
}

contract NestMasterChefIioV2 is NestMasterChef, IioPoolV2 {
    function notifyRewardBegin(uint _lep, /*uint _period,*/ uint _span, uint _begin) virtual override(StakingPool, NestMasterChef) public {
        NestMasterChef.notifyRewardBegin(_lep, /*_period,*/ _span, _begin);
    }
    
    function stake(uint amount) virtual override(NestMasterChef, IioPoolV2) public {
        super.stake(amount);
    }

    function withdraw(uint amount) virtual override(NestMasterChef, IioPoolV2) public {
        super.withdraw(amount);
    }
    
    function exit() virtual override(StakingRewards, NestMasterChef) public {
        NestMasterChef.exit();
    }
    
    
    uint[50] private __gap;
}
    
contract BurningPool is StakingPool {
    address internal constant BurnAddress   = 0x000000000000000000000000000000000000dEaD;
    
    function stake(uint256 amount) virtual override public {
        super.stake(amount);
        stakingToken.safeTransfer(BurnAddress, stakingToken.balanceOf(address(this)));
    }

    function withdraw(uint256) virtual override public {
        revert('Burned already, none to withdraw');
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

contract CompoundPool is StakingPool {
    mapping(address => uint256) public compoundStored;        // 0x0 address for total
    
    function compoundPerToken() virtual public view returns (uint) {
        if (_totalSupply == 0)
            return compoundStored[address(0)];
        return compoundStored[address(0)].add(1e18).mul(rewardDelta().mul(1e18).div(_totalSupply).add(1e18)).div(1e18).sub(1e18);
    }
    
    function totalSupply() virtual override public view returns (uint) {
        return _totalSupply.add(rewards[address(0)]).add(_rewardDelta());
    }

    function balanceOf(address account) virtual override public view returns (uint) {
        uint compound = compoundStored[account];
        if(compound == 0)
            compound = compoundStored[address(0)];
        return _balances[account].add(rewards[account]).mul(compoundPerToken().add(1e18)).div(compound.add(1e18));
    }

    function getRewardA(address payable acct) virtual override public nonReentrant updateReward(acct) {
    }

    function compound() virtual override public nonReentrant updateReward(msg.sender) {
    }    
    
    function earned(address account) virtual override public view returns (uint) {
        return balanceOf(account).sub0(_balances[account]);
	}    
	
    function withdraw(uint256 amount) virtual override public {
        if(amount == uint(-1))
            amount = balanceOf(msg.sender);
        super.withdraw(amount);
    }
    
    function _updateReward(address account) virtual internal returns (uint reward) {
        require(stakingToken == rewardsToken, 'not CompoundPool');
        uint delta = _rewardDelta();
        rewardPerTokenStored = rewardPerToken();
        compoundStored[address(0)] = compoundPerToken();
        lastUpdateTime = now;

        if(delta > 0)
            rewardsToken.safeTransferFrom(rewardsDistribution, address(this), delta);
        
        _totalSupply = totalSupply();
        if(rewards[address(0)] != 0)
            rewards[address(0)] = 0;
        
        if (account != address(0)) {
            uint bal = balanceOf(account);
            reward = bal.sub0(_balances[account]);
            _balances[account] = bal;
            if(rewards[account] != 0)
                rewards[account] = 0;
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
            compoundStored[account] = compoundStored[address(0)];
            emit RewardPaid(account, reward);
            emit Staked(account, reward);
        }

        address addr = address(config[_ecoAddr_]);
        uint ratio = config[_ecoRatio_];
        if(addr != address(0) && ratio != 0) {
            uint d = delta.mul(ratio).div(1e18);
            _balances[addr] = balanceOf(addr).add(d);
            if(rewards[addr] != 0)
                rewards[addr] = 0;
        }
    }

    modifier updateReward(address account) virtual override {
        _updateReward(account);
        _;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[49] private ______gap;
}

contract CompoundPoolStakedToken is CompoundPool, ContextUpgradeSafe, IERC20 {
    mapping (address => mapping (address => uint256)) internal _allowances;

    function name() virtual public view returns (string memory) {
        return string(abi.encodePacked('Staked ', ERC20UpgradeSafe(address(stakingToken)).name()));
    }

    function symbol() virtual public view returns (string memory) {
        return string(abi.encodePacked('s', ERC20UpgradeSafe(address(stakingToken)).symbol()));
    }

    function decimals() virtual public view returns (uint8) {
        return ERC20UpgradeSafe(address(stakingToken)).decimals();
    }

    function totalSupply() virtual override(CompoundPool, IERC20) public view returns (uint) {
        return CompoundPool.totalSupply();
    }

    function balanceOf(address account) virtual override(CompoundPool, IERC20) public view returns (uint) {
        return CompoundPool.balanceOf(account);
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        if(sender != _msgSender() && _allowances[sender][_msgSender()] != uint(-1))
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual updateReward(from) updateReward(to) { 
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual { 
    }

    function _updateReward(address account) virtual override internal returns (uint reward) {
        reward = super._updateReward(account);
        if(reward > 0)
            emit Transfer(address(0), account, reward);
    }
            
    function _stakeTo(uint256 amount, address to) virtual override internal {
        super._stakeTo(amount, to);
        emit Transfer(address(0), to, amount);
    }

    function withdraw(uint256 amount) virtual override public {
        super.withdraw(amount);
        emit Transfer(msg.sender, address(0), amount != uint(-1) ? amount : balanceOf(_msgSender()));
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[49] private __gap;
}

contract TurboPool is StakingPool {
    bytes32 internal constant _turboMax_        = 'turboMax';
    bytes32 internal constant _turboSpan_       = 'turboSpan';
    bytes32 internal constant _stakeTime_       = 'stakeTime';
    
    function __TurboPool_init(address _governor, 
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _ecoAddr,
        uint turboMax_,
        uint turboSpan_
    ) public virtual initializer {
	    __ReentrancyGuard_init_unchained();
	    __Governable_init_unchained(_governor);
        //__StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken, _ecoAddr);
        __TurboPool_init_unchained(turboMax_, turboSpan_);
    }

    function __TurboPool_init_unchained(uint turboMax_, uint turboSpan_) internal virtual governance {
        require(turboSpan_ > 0);
        config[_turboMax_]  = turboMax_;
        config[_turboSpan_] = turboSpan_;
    }

    function turboOf(address acct) public view returns (uint) {
        uint stakeTime = getConfigA(_stakeTime_, acct);
        if(stakeTime == 0)
            return 0;
        uint turboMax  = config[_turboMax_];
        return Math.min(turboMax, turboMax.mul(now.sub(stakeTime)).div(config[_turboSpan_]));
    }
    
    function vTotalSupply() virtual public view returns (uint) {
        return totalSupply().mul(config[_turboMax_].add(1e18)).div(1e18);
    }

    function vBalanceOf(address acct) virtual public view returns (uint) {
        return balanceOf(acct).mul(turboOf(acct).add(1e18)).div(1e18);
    }

    function rewardPerToken() virtual override public view returns (uint256) {
        if(_totalSupply == 0)
            return rewardPerTokenStored;
        return rewardPerTokenStored.add(rewardDelta().mul(1e18).div(vTotalSupply()));
    }

    function earned(address account) virtual override public view returns (uint256 rwd) {
        rwd = vBalanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
        rwd = Math.min(Math.min(rwd, rewardsToken.allowance(rewardsDistribution, address(this))), rewardsToken.balanceOf(rewardsDistribution));
	}    
	
    function _updateStakeTime(address acct, uint256 dAmt) internal {
        uint bal = _balances[acct];
        uint turbo = bal.sub(dAmt).mul(turboOf(acct)).div(bal);
        uint span = config[_turboSpan_].mul(turbo).div(config[_turboMax_]);
        _setConfig(_stakeTime_, now.sub(span));
    }
    
    function _stakeTo(uint256 amount, address to) virtual override internal {
        super._stakeTo(amount, to);
        _updateStakeTime(to, amount);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
}

contract CompoundTurboPool is CompoundPoolStakedToken, TurboPool {
    function totalSupply() virtual override(CompoundPoolStakedToken, StakingRewards) public view returns (uint) {
        return CompoundPoolStakedToken.totalSupply();
    }

    function balanceOf(address account) virtual override(CompoundPoolStakedToken, StakingRewards) public view returns (uint) {
        uint compound = compoundStored[account];
        if(compound == 0)
            compound = compoundStored[address(0)];
        compound = uint(1e18).mul(compoundPerToken().add(1e18)).div(compound.add(1e18)).sub(1e18);
        compound = turboOf(account).add(1e18).mul(compound).div(1e18);
        return _balances[account].add(rewards[account]).mul(compound.add(1e18)).div(1e18);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override { 
        from;
        _updateStakeTime(to, amount);
    }

    function getRewardA(address payable acct) virtual override(CompoundPool, StakingPool) public {
        return CompoundPool.getRewardA(acct);
    }

    function compound() virtual override(CompoundPool, StakingPool) public {
        return CompoundPool.compound();
    }    
    
    function compoundPerToken() virtual override public view returns (uint) {
        uint vTotal = _totalSupply.mul(config[_turboMax_].add(1e18)).div(1e18);
        if (vTotal == 0)
            return compoundStored[address(0)];
        return compoundStored[address(0)].add(1e18).mul(rewardDelta().mul(1e18).div(vTotal).add(1e18)).div(1e18).sub(1e18);
    }
    
    function rewardPerToken() virtual override(TurboPool, StakingPool) public view returns (uint256) {
        return TurboPool.rewardPerToken();
    }

    function earned(address account) virtual override(CompoundPool, TurboPool) public view returns (uint) {
        return CompoundPool.earned(account);
	}    
	
    function _stakeTo(uint256 amount, address to) virtual override(CompoundPoolStakedToken, TurboPool) internal {
        super._stakeTo(amount, to);
    }

    function withdraw(uint256 amount) virtual override(CompoundPoolStakedToken, StakingRewards) public {
        CompoundPoolStakedToken.withdraw(amount);
    }

    function _updateReward(address account) virtual override internal returns (uint reward) {
        require(stakingToken == rewardsToken, 'not CompoundPool');
        uint delta = _rewardDelta();
        uint reducedReward;
        rewardPerTokenStored = rewardPerToken();
        compoundStored[address(0)] = compoundPerToken();
        lastUpdateTime = now;

        if(delta > 0)
            rewardsToken.safeTransferFrom(rewardsDistribution, address(this), delta);
        
        _totalSupply = totalSupply();
        if(rewards[address(0)] != 0)
            rewards[address(0)] = 0;
        
        if (account != address(0)) {
            uint bal = balanceOf(account);
            reward = bal.sub0(_balances[account]);
            reducedReward = CompoundPool.balanceOf(account).sub(_balances[account]).mul(config[_turboMax_].add(1e18)).div(1e18).sub(reward);
            _balances[account] = bal;
            if(rewards[account] != 0)
                rewards[account] = 0;
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
            compoundStored[account] = compoundStored[address(0)];
            emit RewardPaid(account, reward);
            emit Staked(account, reward);
            emit Transfer(address(0), account, reward);
        }

        address addr = address(config[_ecoAddr_]);
        uint ratio = config[_ecoRatio_];
        if(addr != address(0) && ratio != 0) {
            uint d = delta.mul(ratio).div(1e18);
            _balances[addr] = balanceOf(addr).add(d).add(reducedReward);
            if(rewards[addr] != 0)
                rewards[addr] = 0;
        }
    }

    modifier updateReward(address account) virtual override(CompoundPool, StakingPool) {
        _updateReward(account);
        _;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
}

contract Mine is Governable {
    using SafeERC20 for IERC20;

    address public reward;

    function __Mine_init(address governor, address reward_) public initializer {
        __Governable_init_unchained(governor);
        __Mine_init_unchained(reward_);
    }
    
    function __Mine_init_unchained(address reward_) internal governance initializer {
        reward = reward_;
    }
    
    function approvePool(address pool, uint amount) public governance {
        IERC20(reward).approve(pool, amount);
    }
    
    function approveToken(address token, address pool, uint amount) public governance {
        IERC20(token).approve(pool, amount);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

contract Vault is Configurable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 internal constant _rewardToken_ = "rewardToken";
    bytes32 internal constant _rebaseTime_ = "rebaseTime";
    bytes32 internal constant _rebasePeriod_ = "rebasePeriod";
    bytes32 internal constant _factorPrice20_ = "factorPrice20";
    bytes32 internal constant _lpTknMaxRatio_ = "lpTknMaxRatio";
    bytes32 internal constant _lpCurMaxRatio_ = "lpCurMaxRatio";
    bytes32 internal constant _pairTokenA_ = "pairTokenA";
    bytes32 internal constant _swapFactory_ = "swapFactory";
    bytes32 internal constant _swapRouter_ = "swapRouter";
    bytes32 internal constant _mine_ = "mine";

    IDotc public dotc;

    function __Vault_init(address governor, address dotc_) public initializer {
        __Governable_init_unchained(governor);
        __Vault_init_unchained(dotc_);
    }

    function __Vault_init_unchained(address dotc_) internal initializer {
        vaultSetPara(dotc_);
    }

    function vaultSetPara(address dotc_) public governance {
        dotc = IDotc(dotc_);
        config[_rebaseTime_] = now.add(0 days).add(8 hours).sub(now % 8 hours);
        config[_rebasePeriod_] = 8 hours;
        config[_factorPrice20_] = 1.1e18; // price20 = price1 * 1.1
        config[_lpTknMaxRatio_] = 0.10e18; // 10%
        config[_lpCurMaxRatio_] = 0.50e18; // 50%
    }

    function setDotc(address dotc_) public governance {
        dotc = IDotc(dotc_);
    }

    function rebase() public {
        uint256 time = config[_rebaseTime_];
        if (now < time) return;
        uint256 period = config[_rebasePeriod_];
        config[_rebaseTime_] = time.add(period);
        _adjustLiquidity();
    }

    function _adjustLiquidity() internal {
        uint256 curBal = 0;
        uint256 tknBal = 0;
        address tokenA = address(dotc.getConfig(_pairTokenA_));
        address rewardToken = address(dotc.getConfig(_rewardToken_));
        address pair = IUniswapV2Factory(dotc.getConfig(_swapFactory_)).getPair(
            tokenA,
            rewardToken
        );
        if (pair != address(0)) {
            curBal = IERC20(tokenA).balanceOf(pair);
            tknBal = IERC20(rewardToken).balanceOf(pair);
        }
        uint256 curTgt = IERC20(tokenA)
            .balanceOf(address(this))
            .add(curBal)
            .mul(config[_lpCurMaxRatio_])
            .div(1e18);
        uint256 tknR = config[_lpTknMaxRatio_];
        uint256 tknTgt = IERC20(rewardToken)
            .totalSupply()
            .sub(tknBal)
            .mul(tknR)
            .div(uint256(1e18).sub(tknR));
        if (curBal == 0)
            curTgt = tknTgt
                .mul(dotc.price1())
                .div(1e18)
                .mul(config[_factorPrice20_])
                .div(1e18);
        if (curTgt > curBal && tknTgt > tknBal) {
            uint256 needTkn = tknBal.mul(curTgt).div(curBal).sub(tknBal);
            if (needTkn > (tknTgt - tknBal)) needTkn = (tknTgt - tknBal);
            _addLiquidity(curTgt - curBal, needTkn);
        }
    }

    function _addLiquidity(uint256 value, uint256 amount) internal {
        address rewardToken = address(dotc.getConfig(_rewardToken_));
        IERC20(rewardToken).safeTransferFrom(
            address(dotc.getConfig(_mine_)),
            address(this),
            amount
        );
        address tokenA = address(dotc.getConfig(_pairTokenA_));
        IUniswapV2Router01 router = IUniswapV2Router01(
            dotc.getConfig(_swapRouter_)
        );
        IERC20(tokenA).safeApprove_(address(router), value);
        IERC20(rewardToken).approve(address(router), amount);
        router.addLiquidity(
            tokenA,
            rewardToken,
            value,
            amount,
            0,
            0,
            address(this),
            now
        );
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

interface IDotc {
    function getConfig(bytes32 key) external view returns (uint256);

    function price1() external view returns (uint256);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router01 {
    //function factory() external pure returns (address);
    function WETH() external pure returns (address);

    //function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}