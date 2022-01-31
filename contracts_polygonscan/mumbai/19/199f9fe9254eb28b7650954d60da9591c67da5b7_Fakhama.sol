/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract Fakhama is IERC20
{
    mapping(address => uint256) private _balances;

    mapping(uint=>User) public map_Users;
    mapping(address=>uint) public map_UserIds;
    mapping(uint=>Rank) public map_ranks;
    mapping(uint8=>uint) LevelPercentage;

    mapping(uint=>mapping(uint=>UserLevelInfo)) map_UserLevelInfo;

    address public owner;
    address public marketingAddress;
    address public vipCommunity;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    struct User
    {
        uint Id;
        address Address;
        uint SponsorId;
        uint Business;
        uint NextRankBusiness;
        uint Investment;
        uint RankId;
        uint[] DirectIds;
        uint ROIDividend;
        uint[] LevelDividend;
        uint DividendWithdrawn;
    }

    struct Rank
    {
        uint Id;
        string Name;
        uint Business;
        uint RequiredRankQualifiers;
    }

    struct UserInfo
    {
        User UserInfo;
        string CurrentRankName;
        string NextRankName;
        uint RequiredBusinessForNextRank;
        uint CoinRate;
        uint CoinsHolding;
        uint CurrentRankId;
        uint TotalLevelDividend;
    }

    struct RankInfo
    {
        uint Id;
        string RankName;
        uint ReqBusiness;
        uint UserBusiness;
        uint ReqDirects;
        uint UserDirects;
        string Status;
    }
    
    struct UserLevelInfo
    {
        uint MemberCount;
        uint Investment;
    }

    uint TotalUser = 0;
    uint VIPCommunityPercentage = 1;
    uint MarketingFeePercentage = 2;
    uint _initialCoinRate = 100000000;
    uint public TotalHoldings=0;

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        require(_totalSupply>=amount, "Invalid amount of tokens!");

        _balances[account] = accountBalance - amount;
        
        _totalSupply -= amount;
    }

    constructor(address _owner, address _marketingAddress, address _vipCommunity)
    {
        _name = "Fakhama";
        _symbol = "FKT";

        owner = _owner;
        marketingAddress = _marketingAddress;
        vipCommunity = _vipCommunity;

        LevelPercentage[1] = 90;
        LevelPercentage[2] = 30;
        LevelPercentage[3] = 20;
        LevelPercentage[4] = 15;//Decimal values cannot be stored. So, later on, divide by 10.
        LevelPercentage[5] = 15;
        LevelPercentage[6] = 20;

        map_ranks[1] = Rank({
            Id:1,
            Name:"Executive",
            Business:0,
            RequiredRankQualifiers:0
        });

        map_ranks[2] = Rank({
            Id:2,
            Name:"Sales Executive",
            Business:5000,
            RequiredRankQualifiers:5
        });
       
        map_ranks[3] = Rank({
            Id:3,
            Name:"Sales Manager",
            Business:12000,
            RequiredRankQualifiers:2
        });

        map_ranks[4] = Rank({
            Id:4,
            Name:"Area Sales Manager",
            Business:25000,
            RequiredRankQualifiers:2
        });

        map_ranks[5] = Rank({
            Id:5,
            Name:"Zonal Head",
            Business:55000,
            RequiredRankQualifiers:2
        });

        map_ranks[6] = Rank({
            Id:6,
            Name:"Project Director",
            Business:120000,
            RequiredRankQualifiers:2
        });

        uint Id=TotalUser+1;
        User memory u = User({
            Id:Id,
            Address:_owner,
            SponsorId:0,
            Business:0,
            NextRankBusiness:0,
            Investment:0,
            RankId:1,
            DirectIds:new uint[](0),
            ROIDividend:0,
            LevelDividend:new uint[](6),
            DividendWithdrawn:0
        });
        
        map_Users[Id]=u;
        map_UserIds[_owner] = Id;
        _balances[msg.sender] = 10**18;

        TotalUser++;
        
    }

    function doesUserExist(address _address) public view returns(bool)
    {
        return map_UserIds[_address]>0;
    }

    fallback() external payable
    {
        return investInternal(owner);
    }

    receive() external payable 
    {
        return investInternal(owner);
    }

    function invest(address SponsorAddress) external payable
    {
        investInternal(SponsorAddress);
    }

    function investInternal(address _SponsorAddress) private
    {
        address _senderAddress = msg.sender;

        require(msg.value>0, "Invalid amount!");

        if(!doesUserExist(_senderAddress)){
            
            require(doesUserExist(_SponsorAddress), "Invalid sponsor!");

            uint SponsorId = map_UserIds[_SponsorAddress];
            uint Id=TotalUser+1;

            User memory u = User({
                Id:Id,
                Address:_senderAddress,
                SponsorId:SponsorId,
                Business:0,
                NextRankBusiness:0,    
                Investment:0,
                RankId:1,
                DirectIds:new uint[](0),
                ROIDividend:0,
                LevelDividend:new uint[](6),
                DividendWithdrawn:0
            });

            map_Users[Id]=u;
            map_UserIds[_senderAddress] = Id;

            TotalUser++;

            map_Users[SponsorId].DirectIds.push(Id);

            newInvestment_Internal(Id, msg.value, true);
        }
        else{
            newInvestment();
        }
    }

    function newInvestment() public payable
    {
        address _senderAddress = msg.sender;
        require(doesUserExist(_senderAddress), "Invalid user!");
        require(msg.value>0, "Invalid amount!");

        newInvestment_Internal(map_UserIds[_senderAddress], msg.value, false);
    }

    function newInvestment_Internal(uint memberId, uint amount, bool isFromRegistration) internal
    {
        uint tokens = (amount*60*getCoinRate(memberId))/(100*10**18);

        map_Users[memberId].Investment+=amount;

        _mint(map_Users[memberId].Address, tokens);
        
        TotalHoldings+=amount;

        uint8 level=1;
        uint _spId = map_Users[memberId].SponsorId;

        while(_spId>0){
            map_Users[_spId].Business+=amount;
            map_Users[_spId].NextRankBusiness+=amount;

            map_UserLevelInfo[_spId][level].Investment+=amount;

            if(isFromRegistration)
            {
                map_UserLevelInfo[_spId][level].MemberCount++;
            }

            updateRank(_spId);

            if(level>=1 && level<=6)
            {
                uint _levelIncome = (amount*LevelPercentage[level])/(100*10);

                if(map_Users[_spId].RankId>=level)
                {
                    map_Users[_spId].LevelDividend[level-1]+=_levelIncome;
                }
            }

            _spId = map_Users[_spId].SponsorId;
            level++;
        }

        payable(marketingAddress).transfer(amount*MarketingFeePercentage/100);
        payable(vipCommunity).transfer(amount*VIPCommunityPercentage/100);

        distributeROI(memberId, amount*18/100);
    }

    function distributeROI(uint onMemberId, uint _amt) internal
    {
        uint _rate = _amt/_totalSupply;

        if(_rate>0)
        {
            uint currentId=1;
            
            while(currentId<=TotalUser)
            {
                if(currentId!=onMemberId)
                {
                    uint _divs = _balances[map_Users[currentId].Address]*_rate;
                    map_Users[currentId].ROIDividend+=_divs;
                }
                currentId++;
            }
            
            /*
            while(currentId<=29000)
            {
                if(currentId!=onMemberId)
                {
                    uint _divs = map_Users[1].TokenHolding*_rate;
                    map_Users[1].Dividend+=_divs;
                }
                currentId++;
            }
            */
        }
    }

    function updateRank(uint _memberId) internal
    {
        uint currentRank = map_Users[_memberId].RankId;
        uint nextRank = currentRank+1;

        if(map_Users[_memberId].NextRankBusiness>=map_ranks[nextRank].Business*(10**18)
                                        &&
            getDirectsCountByRank(_memberId, currentRank)>=map_ranks[nextRank].RequiredRankQualifiers)
        {
            map_Users[_memberId].NextRankBusiness-=(map_ranks[nextRank].Business*(10**18));
            map_Users[_memberId].RankId = nextRank;
            updateRank(_memberId);
        }
    }

    function getDirectsCountByRank(uint _spId, uint _rankId) public view returns(uint)
    {
        uint count=0;

        for(uint i=0;i<map_Users[_spId].DirectIds.length;i++)
        {
            if(count>=map_ranks[_rankId+1].RequiredRankQualifiers)
            {
                break;
            }
            if(map_Users[map_Users[_spId].DirectIds[i]].RankId>=_rankId)
            {
                count++;
            }
        }

        return count;
    }

    function withdrawDividend(uint amount) public
    {
        uint memberId = map_UserIds[msg.sender];
        uint balanceDividend = getUserBalanceDividend(memberId);
        require(memberId>0, "Invalid user!");
        require(balanceDividend>=amount, "Insufficient dividend to withdraw!");

        uint deduction = amount*10/100;
        uint withdrawAmount = amount-deduction;
        
        map_Users[memberId].DividendWithdrawn+=amount;

        uint roi = amount*9/100;
        distributeROI(memberId, roi);

        payable(msg.sender).transfer(withdrawAmount);
        payable(marketingAddress).transfer(deduction-roi);//1% to marketing address
    }

    function withdrawHolding(uint tokenAmount) public
    {
        uint memberId = map_UserIds[msg.sender];
        require(memberId>0, "Invalid user!");
        require(_balances[msg.sender]>=tokenAmount, "Insufficient token balance!");

        uint maticAmount = tokensToMatic(tokenAmount, memberId);

        require(address(this).balance>=maticAmount, "Insufficient fund in contract!");

        uint deduction = (maticAmount*10)/100;
        uint withdrawAmount = maticAmount-deduction;
        
        _burn(msg.sender, tokenAmount);

        if(TotalHoldings>=maticAmount)
        {
            TotalHoldings-=maticAmount;
        }
        else
        {
            TotalHoldings=0;
        }

        payable(msg.sender).transfer(withdrawAmount);
        payable(owner).transfer(deduction);
    }

    function tokensToMatic(uint tokenAmount, uint memberId) public view returns(uint)
    {
        return tokenAmount*(10**18)/getCoinRate(memberId);
    }

    function coinRate() public view returns(uint)
    {
        return TotalHoldings>=(10**18)?_initialCoinRate*(10**18)/TotalHoldings:_initialCoinRate;
    }

    function getCoinRate(uint memberId) public view returns(uint)
    {
        uint temp_holdings = TotalHoldings>map_Users[memberId].Investment?(TotalHoldings-(map_Users[memberId].Investment)):0;
        return temp_holdings>=(10**18)?_initialCoinRate*(10**18)/temp_holdings:_initialCoinRate;
    }

    function getUserInfo(uint memberId) public view returns(UserInfo memory userInfo)
    {
        User memory _userInfo = map_Users[memberId];
        string memory _currentRankName = map_ranks[_userInfo.RankId].Name;
        string memory _nextRankName = _userInfo.RankId<6?map_ranks[_userInfo.RankId+1].Name:"";
        uint _requiredBusinessForNextRank = map_ranks[_userInfo.RankId+1].Business;
        uint _coinRate = getCoinRate(memberId);
        uint _coinsHolding = _balances[_userInfo.Address];
        uint _totalLevelDividend = getMemberTotalLevelDividend(memberId);

        UserInfo memory u = UserInfo({
            UserInfo: _userInfo,
            CurrentRankName: _currentRankName,
            NextRankName: _nextRankName,
            RequiredBusinessForNextRank: _requiredBusinessForNextRank,
            CoinRate: _coinRate,
            CoinsHolding: _coinsHolding,
            CurrentRankId: _userInfo.RankId,
            TotalLevelDividend: _totalLevelDividend
        });

        return (u);
    }

    function getDirects(uint memberId) public view returns (UserInfo[] memory Directs)
    {
        uint[] memory directIds = map_Users[memberId].DirectIds;
        UserInfo[] memory _directsInfo=new UserInfo[](directIds.length);

        for(uint i=0; i<directIds.length; i++)
        {
            _directsInfo[i] = getUserInfo(directIds[i]);
        }
        return _directsInfo;
    }

    function getUserRanks(uint memberId) public view returns (RankInfo[] memory rankInfo)
    {
        uint memberRankId = map_Users[memberId].RankId;
        uint memberBusiness = map_Users[memberId].Business;

        RankInfo[] memory _rankInfo = new RankInfo[](6);

        for(uint i=1;i<=6;i++)
        {
            Rank memory r = map_ranks[i];
            RankInfo memory temp_RankInfo = RankInfo({
                Id:i,
                RankName:r.Name,
                ReqBusiness:r.Business,
                UserBusiness:memberBusiness>r.Business*10**18?r.Business*10**18:memberBusiness,
                ReqDirects:r.RequiredRankQualifiers,
                UserDirects:getDirectsCountByRank(memberId, i-1),
                Status:memberRankId>=i?"Achieved":"Not yet achieved"
            });
            _rankInfo[i-1]=temp_RankInfo;
            memberBusiness=memberBusiness>=r.Business*10**18?memberBusiness-(r.Business*10**18):0;
        }
        return _rankInfo;
    }

    function getUserBalanceDividend(uint memberId) public view returns (uint)
    {
        return map_Users[memberId].ROIDividend + getMemberTotalLevelDividend(memberId) - map_Users[memberId].DividendWithdrawn;
    }

    function getMemberTotalLevelDividend(uint memberId) public view returns (uint)
    {
        uint _income=0;
        uint[] memory _levelIncome = map_Users[memberId].LevelDividend;
        for(uint i=0;i<_levelIncome.length;i++)
        {
            _income+=_levelIncome[i];
        }
        return _income;
    }

    function getMemberLevelDividend(uint memberId) public view returns (UserLevelInfo[] memory LevelInfo, uint[] memory Percentage)
    {
        UserLevelInfo[] memory _info = new UserLevelInfo[](6);
        uint[] memory _levelPercentage = new uint[](6);
        for(uint8 i=1; i<=6; i++)
        {
            _info[i-1]=map_UserLevelInfo[memberId][i];
            _levelPercentage[i-1]=LevelPercentage[i];
        }

        return (_info, _levelPercentage);
    }

}