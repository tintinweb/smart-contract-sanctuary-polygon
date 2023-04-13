/**
 *Submitted for verification at polygonscan.com on 2023-04-12
*/

pragma solidity >=0.4.22 <0.9.0;
// SPDX-License-Identifier: UNLICENSED
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ROI_POOL{
    
    address private owner;
    IERC20 private Token;
    address private tokenAddr;
    address private Relayer;
    uint private limit1 = 1;
    uint private limit2 = 10000;
    mapping(address=>uint) private UserBalanceByAddr;
    mapping(address=>uint) private UsersReferralCodes;
    mapping(uint=>address) private ReferralToAddress;
    mapping(address=>uint) private TotalWithdraw;
    mapping(uint=>uint[])  private Referrals;
    mapping(address=>uint) private UsersLevel;
    mapping(address=>uint) private TotalProfit;
    mapping(address=>uint) private ReferredBy;
    mapping(address=>uint) private club;
    mapping(address=>uint) private ROILevelIncome;
    mapping(address=>uint) private ROIIncome;
    mapping(address=>uint) private DirectReferralIncome;
    mapping(address=>uint) private TotalEarnedFromClubs;
    mapping(address=>uint) private SelectedPackage;
    mapping(address=>uint) private TotalEarnedFromClub1;
    mapping(address=>uint) private TotalEarnedFromClub2;
    mapping(address=>uint) private TotalEarnedFromClub3;

    uint private club1;
    uint private club2;
    uint private club3;
    uint private Totalclub1;
    uint private Totalclub2;
    uint private Totalclub3;
    uint private PoolOwner1;
    uint private PoolCoreTeam;
    uint[] private IDS;

 
    constructor(){
        tokenAddr = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        Token = IERC20(tokenAddr);
        owner = msg.sender;  
	    IDS.push(0);
        ReferralToAddress[0] = msg.sender;   // setting address on refferel   
    }


    modifier onlyOwner{
      require(msg.sender == owner);
      _;
   }

   function getTotalEarnedFromClubs() view public returns(uint){
       return TotalEarnedFromClubs[msg.sender];
    }

    function getTotalClubAmmounts() view public returns(uint,uint,uint){
        return (TotalEarnedFromClub1[msg.sender],TotalEarnedFromClub2[msg.sender],TotalEarnedFromClub3[msg.sender]);
    }

    function getClubIncomeForCurrUser() view public returns(uint,uint){
        if(club[msg.sender] == 1 && club1 >= Totalclub1){  
            return (club1 / Totalclub1, club[msg.sender]);
        }else if(club[msg.sender] == 2 && club2 >= Totalclub2){
            return (club2 / Totalclub2, club[msg.sender]);
        }else if(club[msg.sender] == 3 && club3 >= Totalclub3){
            return (club3 / Totalclub3, club[msg.sender]);
        }else{
            return (0,club[msg.sender]);
        }
    }



    function getPackage() view public returns(uint){  
        return SelectedPackage[msg.sender];
    }

    function getReffLen(address addr) view public returns(uint){  
        return Referrals[UsersReferralCodes[addr]].length;
    }

    function getInvitedPartners() view public returns(uint){   // direct referrals
        return Referrals[UsersReferralCodes[msg.sender]].length;
    }

    function getDailyIncome() view public returns(uint){       // ROI Income
        return ROIIncome[msg.sender];
    }

    function getTotalReffIncome() view public returns(uint){  // ROI Level Income
        return ROILevelIncome[msg.sender]; 
    }

    function getTotalProfit() view public returns(uint){    // Total Income
        return TotalProfit[msg.sender];
    }

    function getMyBalance() view public returns(uint){    
        return UserBalanceByAddr[msg.sender];
    }

    function getMyID() view public returns(uint){
        return UsersReferralCodes[msg.sender];
    }

    function getTotalWithdraw() view public returns(uint){
        return TotalWithdraw[msg.sender];
    }

    function getClub() view public returns(uint){
        uint tempVar = getAllReffs(msg.sender, true);
        uint teamLength = getTeamLength(msg.sender);
        uint CurrClub = getClubLevel(tempVar, teamLength, msg.sender);
        return CurrClub;
    }

    function getAdmin() view public returns(address){
        return owner;
    }

    function getDirectIncome() view public returns(uint){
        return DirectReferralIncome[msg.sender];
    }

    function getTotalTeamBusiness() view public returns(uint) {
        uint temp;
        for(uint i = 0; i < Referrals[UsersReferralCodes[msg.sender]].length; i++){
            temp = temp + SelectedPackage[ReferralToAddress[Referrals[UsersReferralCodes[msg.sender]][i]]];
        }
        return temp;
    }

    // ------------------ ADMIN FUNCTIONS --------------------- //

    function getAllClubsAmount() view public onlyOwner returns(uint,uint,uint){
        return (club1,club2,club3);
    }

    function getAllClubsMem() view public onlyOwner returns(uint,uint,uint){
        return (Totalclub1,Totalclub2,Totalclub3);
    }

    function smartContractBalance() view public onlyOwner returns(uint){
        return Token.balanceOf(address(this));
    }

    function poolOwnerTAX() view public onlyOwner returns(uint) {
        return PoolOwner1;
    }

    function PoolCoreTeamTAX() view public onlyOwner returns(uint){
        return PoolCoreTeam;
    }


    function changeOwner(address newOwner) public onlyOwner{
        require(UsersReferralCodes[newOwner] == 0, "Please select any other wallet which is not already registered in ROI pool");
        owner = newOwner;
        ReferralToAddress[0] = newOwner;  
    }


    function getClubIncome() view public returns(uint){
        if(club[msg.sender] == 1){
            return club1;
        }else if(club[msg.sender] == 2){
            return club2;
        }else if(club[msg.sender] == 3){
            return club3;
        }else{
            return 0;
        }
    }
    



    function JOIN(uint reffCode, uint amount) public {              // remove the addr and set msg.sender once project is for live
        require(amount <= 5000 && amount >= 100, "You can not deposit more than $5000 and less than $100");
        require(msg.sender!=owner, "Owner can not join pool");
        Token.transferFrom(msg.sender, address(this), amount * 10 ** 6);
        if(UsersReferralCodes[msg.sender]!=0){
            UserBalanceByAddr[msg.sender] += amount * 10 ** 6;
            SelectedPackage[msg.sender] += amount * 10 ** 6;
            updateLevel(ReferredBy[msg.sender]); // update level
        }else{
            require(ReferralToAddress[reffCode]!=address(0), "referral code does not exist");      
            bool repeat = true;
            while(repeat){
                uint temp = generateRandomNumber();
                if(ReferralToAddress[temp] == address(0)){
                    UsersReferralCodes[msg.sender] = temp; // Get remainder after dividing by 100000 // setting refferel number
                    ReferralToAddress[temp] = msg.sender;   // setting address on refferel
                    IDS.push(temp);
                    repeat = false;
                }
            }
            UserBalanceByAddr[msg.sender] = amount * 10 ** 6;        // setting balance with 6 zeros at the end
            PoolOwner1 += UserBalanceByAddr[msg.sender] * 200 / 10000;   // 2% pool owner 1
            PoolCoreTeam += UserBalanceByAddr[msg.sender] * 200 / 10000; // 2% pool core team
            club1 += UserBalanceByAddr[msg.sender] * 100 / 10000;   // 1% for club 1
            club2 += UserBalanceByAddr[msg.sender] * 100 / 10000;  //  1% for club 2
            club3 += UserBalanceByAddr[msg.sender] * 200 / 10000; //   2% for club 3
            SelectedPackage[msg.sender] = UserBalanceByAddr[msg.sender];
            // -- adding increments to inviter stats -- //
            Referrals[reffCode].push(UsersReferralCodes[msg.sender]); // pushing current user referral code to the referral's array
            ReferredBy[msg.sender] = reffCode;                     // setting referral code
            updateLevel(reffCode);                          // update level
            updateClub(ReferralToAddress[reffCode]);
            DirectReferralIncome[ReferralToAddress[reffCode]] += UserBalanceByAddr[msg.sender] * 500 / 10000;
            TotalProfit[ReferralToAddress[reffCode]] += UserBalanceByAddr[msg.sender] * 500 / 10000;
            UserBalanceByAddr[ReferralToAddress[reffCode]] += UserBalanceByAddr[msg.sender] * 500 / 10000;
        }
        
    }

    function withdraw(uint amount) public {
        require(UsersReferralCodes[msg.sender] != 0, "you are not listed");
        require(amount <= UserBalanceByAddr[msg.sender] - SelectedPackage[msg.sender], "Invalid Balance");
        Token.transfer(msg.sender, amount);
        TotalWithdraw[msg.sender] += amount;
        UserBalanceByAddr[msg.sender] -= amount;
    }

    function claimPoolOwnerTax() public onlyOwner{
        Token.transfer(msg.sender, PoolOwner1);
        PoolOwner1 = 0;
    }

    function claimCoreTeamTax() public onlyOwner{
        Token.transfer(msg.sender, PoolCoreTeam);
        PoolCoreTeam = 0;
    }

    


    function updateLevel(uint reffCode) internal {
        if(Referrals[reffCode].length >= 10 ){
            UsersLevel[ReferralToAddress[reffCode]] = 20; 
        }else if(Referrals[reffCode].length >= 9){
            UsersLevel[ReferralToAddress[reffCode]] = 18;
        }else if(Referrals[reffCode].length >= 8){
            UsersLevel[ReferralToAddress[reffCode]] = 16;
        }else if(Referrals[reffCode].length >= 7){
            UsersLevel[ReferralToAddress[reffCode]] = 15;
        }else if(Referrals[reffCode].length >= 6){
            UsersLevel[ReferralToAddress[reffCode]] = 12;
        }else if(Referrals[reffCode].length >= 5){
            UsersLevel[ReferralToAddress[reffCode]] = 10;
        }else if(Referrals[reffCode].length >= 4){
            UsersLevel[ReferralToAddress[reffCode]] = 8;
        }else if(Referrals[reffCode].length >= 3){
            UsersLevel[ReferralToAddress[reffCode]] = 6;
        }else if(Referrals[reffCode].length >= 2){
            UsersLevel[ReferralToAddress[reffCode]] = 4;
        }else if(Referrals[reffCode].length >= 1){
            UsersLevel[ReferralToAddress[reffCode]] = 2;
        }else{
        }
    }



    function updateClub(address addr) internal {
        
        uint teamWorth = getAllReffs(addr, true);   
        uint teamLength = getTeamLength(addr);
        if(UserBalanceByAddr[addr] >= 100000000000000000000 && UserBalanceByAddr[addr] < 2500000000000000000000){
            if(teamWorth >= 20000000000000000000000 && teamWorth < 50000000000000000000000 && teamLength >= 50 && teamLength < 200){
                if(club[addr]==0){
                    club[addr] = 1;
                    Totalclub1++;
                }else if(club[addr]==1){
                    
                }else if(club[addr]==2){
                    Totalclub2--;
                    club[addr] = 1;
                    Totalclub1++;
                }else if(club[addr]==3){
                    Totalclub3--;
                    club[addr] = 1;
                    Totalclub1++;
                }
            }else if(teamWorth >= 50000000000000000000000 && teamWorth < 150000000000000000000000 && teamLength >= 200 && teamLength < 500){
                if(club[addr]==0){
                    Totalclub2++;
                    club[addr] = 2;
                }else if(club[addr]==1){
                    Totalclub1--;
                    club[addr] = 2;
                    Totalclub2++;
                }else if(club[addr]==2){
                    
                }else if(club[addr]==3){
                    Totalclub3--;
                    club[addr] = 2;
                    Totalclub2++;
                }
                
            }else{

            }
        }else if(UserBalanceByAddr[addr] >= 2500000000000000000000 && teamWorth >= 150000000000000000000000  && teamLength >= 500){
            if(club[addr]==0){
                Totalclub3++;
                club[addr] = 3;
            }else if(club[addr]==1){
                Totalclub1--;
                club[addr] = 3;
                Totalclub3++;
            }else if(club[addr]==2){
                Totalclub2--;
                club[addr] = 3;
                Totalclub3++;
            }else if(club[addr]==3){
            }
        }else{

        }
    }

    function getClubLevel(uint teamWorth, uint teamLength , address addr) view internal returns(uint){
        if(UserBalanceByAddr[addr] >= 100000000000000000000 && UserBalanceByAddr[addr] < 2500000000000000000000){
            if(teamWorth >= 20000000000000000000000 && teamWorth < 50000000000000000000000 && teamLength >= 50 && teamLength < 200){
                return 1;
            }else if(teamWorth >= 50000000000000000000000 && teamWorth < 150000000000000000000000 && teamLength >= 200 && teamLength < 500){
                return 2;
            }else{
                return 0;
            }
        }else if(UserBalanceByAddr[addr] >= 2500000000000000000000 && teamWorth >= 150000000000000000000000  && teamLength >= 500){
            return 3;
        }else{
            return 0;
        }
    }

    function changeLimit1(uint a) public onlyOwner{
        limit1 = a;
    }
    function changeLimit2(uint b) public onlyOwner{
        limit2 = b;
    }
    
    function ChangeRelayer(address newRelayer) public onlyOwner{
        Relayer = newRelayer;
    }

    function generateRandomNumber() public view returns (uint256) {
        uint256 random = uint256(block.timestamp) % limit2;
        return random + limit1;
    }

    function Daily1Per() public returns(bool){
        require(msg.sender == Relayer, "You can not run this function please check relayer");
        uint tempVar;
        uint ToBePaid;
        for(uint i = 1 ; i < IDS.length ; i++){
            if(TotalProfit[ReferralToAddress[IDS[i]]] >= (SelectedPackage[ReferralToAddress[IDS[i]]] * 200 / 100 )){
                Token.transfer(ReferralToAddress[IDS[i]], UserBalanceByAddr[ReferralToAddress[IDS[i]]] - SelectedPackage[ReferralToAddress[IDS[i]]]);
                TotalWithdraw[ReferralToAddress[IDS[i]]] = 0;
                TotalProfit[ReferralToAddress[IDS[i]]] = 0;
                UserBalanceByAddr[ReferralToAddress[IDS[i]]] = 0;
                SelectedPackage[ReferralToAddress[IDS[i]]] = 0;
                ROILevelIncome[ReferralToAddress[IDS[i]]] = 0;
                ROIIncome[ReferralToAddress[IDS[i]]] = 0;
                DirectReferralIncome[ReferralToAddress[IDS[i]]] = 0;
                TotalEarnedFromClubs[ReferralToAddress[IDS[i]]] = 0;
                updateLevel(ReferredBy[ReferralToAddress[IDS[i]]]);                          
                updateClub(ReferralToAddress[ReferredBy[ReferralToAddress[IDS[i]]]]);
            }else if(SelectedPackage[ReferralToAddress[IDS[i]]] > 0){
                ToBePaid = SelectedPackage[ReferralToAddress[IDS[i]]] * 50 / 10000;
                uint temper = ToBePaid;
                ROIIncome[ReferralToAddress[IDS[i]]] += ToBePaid;
                if(UsersLevel[ReferralToAddress[IDS[i]]]>0){
                    tempVar = getAllReffs(ReferralToAddress[IDS[i]], false);
                    ToBePaid += tempVar;
                    ROILevelIncome[ReferralToAddress[IDS[i]]] += tempVar;
                }
                tempVar = getAllReffs(ReferralToAddress[IDS[i]], true);
                uint teamLength = getTeamLength(ReferralToAddress[IDS[i]]);
                uint CurrClub = getClubLevel(tempVar, teamLength, ReferralToAddress[IDS[i]]);
                teamLength = ToBePaid;   // total profit and balance
                temper = ToBePaid;
                if(CurrClub != club[ReferralToAddress[IDS[i]]]){
                    updateClub(ReferralToAddress[IDS[i]]);
                }
                if(club[ReferralToAddress[IDS[i]]] != 0){
                    if(club[ReferralToAddress[IDS[i]]] == 1 && club1 >= Totalclub1){
                        teamLength += club1 / Totalclub1;
                        TotalEarnedFromClub1[ReferralToAddress[IDS[i]]] += club1 / Totalclub1;
                    }else if(club[ReferralToAddress[IDS[i]]] == 2 && club2 >= Totalclub2){
                        teamLength += club2 / Totalclub2;
                        TotalEarnedFromClub2[ReferralToAddress[IDS[i]]] += club2 / Totalclub2;
                    }else if(club[ReferralToAddress[IDS[i]]] == 3 && club3 >= Totalclub3){
                        teamLength += club3 / Totalclub3;
                        TotalEarnedFromClub3[ReferralToAddress[IDS[i]]] += club3 / Totalclub3;
                    }
                    TotalEarnedFromClubs[ReferralToAddress[IDS[i]]] += ToBePaid - temper;
                }
                TotalProfit[ReferralToAddress[IDS[i]]] += teamLength;
                UserBalanceByAddr[ReferralToAddress[IDS[i]]] += teamLength;
            }
        }
        if(club1 >= Totalclub1 && Totalclub1 > 0 ){
            delete club1;
        }else if(club2 >= Totalclub2 && Totalclub2 > 0){
            delete club2;
        }else if(club3 >= Totalclub3 && Totalclub3 > 0){
            delete club3;
        }
        return true;
    }

 
    
    function getAllReffs(address addr, bool getWorth) public view returns(uint) {
        uint[] memory CurrLevelReffs = new uint[](Referrals[UsersReferralCodes[addr]].length);
        uint[] memory tempArr = new uint[](Referrals[UsersReferralCodes[addr]].length);
        uint[] memory AmountToBePaid = new uint[](UsersLevel[addr]+1);
        uint[] memory LevelPer = new uint[](12);
        LevelPer[0] = 5000;  
        LevelPer[1] = 1000;
        LevelPer[2] = 1000;
        LevelPer[3] = 1000;
        LevelPer[4] = 1000;
        LevelPer[5] = 500;
        LevelPer[6] = 500;
        LevelPer[7] = 500;
        LevelPer[8] = 500;
        LevelPer[9] = 500;
        LevelPer[10] = 500;
        LevelPer[11] = Referrals[UsersReferralCodes[addr]].length;
        
        if(UsersLevel[addr] >= 1){
            for(uint i = 0; i < Referrals[UsersReferralCodes[addr]].length; i++){
                if(getWorth == true){
                    uint a = UsersReferralCodes[addr];
                    uint b = Referrals[a][i];
                    address c = ReferralToAddress[b];
                    AmountToBePaid[i+1] += ((UserBalanceByAddr[c] + TotalWithdraw[c]) - TotalProfit[c]);
                }else{
                    AmountToBePaid[0] += SelectedPackage[ReferralToAddress[Referrals[UsersReferralCodes[addr]][i]]];
                }
                
                CurrLevelReffs[i] = Referrals[UsersReferralCodes[addr]][i];
            }
            if(getWorth == false){
                AmountToBePaid[0] = AmountToBePaid[0] * LevelPer[0] /10000;
                AmountToBePaid[0] = AmountToBePaid[0] * 50 / 10000;
            }
            if(UsersLevel[addr]>1){
                for(uint i = 0 ; i < UsersLevel[addr]-1; i++){
                    LevelPer[11] = getReffLen(CurrLevelReffs);
                    if(LevelPer[11] > 0) {
                        tempArr = new uint[](LevelPer[11]);
                        tempArr = getReff(CurrLevelReffs, LevelPer[11]);
                        delete CurrLevelReffs;
                        CurrLevelReffs = new uint[](tempArr.length);
                            for(uint j = 0 ; j < tempArr.length ; j++){
                                AmountToBePaid[i+1] += SelectedPackage[ReferralToAddress[tempArr[j]]];
                                CurrLevelReffs[j] = tempArr[j];
                            }
                        if(getWorth == false){
                            if(i > 9){
                                AmountToBePaid[i+1] = AmountToBePaid[i+1] * 200 /10000;
                            }else{
                                AmountToBePaid[i+1] = AmountToBePaid[i+1] * LevelPer[i+1] /10000;
                            }
                            AmountToBePaid[i+1] = AmountToBePaid[i+1] * 50 / 10000;
                        }
                        delete tempArr;
                    }
                }
            }

        }
        LevelPer[11] = 0;
        for(uint i = 0 ; i < AmountToBePaid.length ; i++){
            LevelPer[11] += AmountToBePaid[i];
        }
        return LevelPer[11];
    }


    
   

    
    function getTeamLength(address addr) public view returns(uint){
        uint[] memory CurrLevelReffs = new uint[](Referrals[UsersReferralCodes[addr]].length);
        uint[] memory tempArr = new uint[](Referrals[UsersReferralCodes[addr]].length);
        uint teamLength = Referrals[UsersReferralCodes[addr]].length;
        uint len = Referrals[UsersReferralCodes[addr]].length;
        
        if(UsersLevel[addr] >= 1){
            for(uint i = 0; i < Referrals[UsersReferralCodes[addr]].length; i++){
            CurrLevelReffs[i] = Referrals[UsersReferralCodes[addr]][i];
            }
            if(UsersLevel[addr]>1){
                for(uint i = 0 ; i < UsersLevel[addr]-1; i++){
                    len = getReffLen(CurrLevelReffs);
                    if(len > 0) {
                        tempArr = new uint[](len);
                        tempArr = getReff(CurrLevelReffs, len);
                        delete CurrLevelReffs;
                        CurrLevelReffs = new uint[](tempArr.length);
                            for(uint j = 0 ; j < tempArr.length ; j++){
                                if(tempArr[j]!=0){
                                    teamLength++;
                                }
                                CurrLevelReffs[j] = tempArr[j];
                                // calculate the amount for i level here later
                            }
                        delete tempArr;
                    }
                }
            }
        }
        return teamLength;
    }

    function getReffLen(uint[] memory CurrRefArr) view internal returns(uint){
        uint tempLen;
        for(uint i = 0 ; i < CurrRefArr.length ; i++ ){
            tempLen =  tempLen + Referrals[CurrRefArr[i]].length ;
        }
        return tempLen;
    }

 
    function getReff(uint[] memory CurrRefArr, uint Len) view internal returns(uint[] memory){
        uint[] memory CurrLevelReffs = new uint[](Len);
        uint tempLen = 0; 
 
        for(uint i = 0 ; i < CurrRefArr.length ; i++ ){
            for(uint j = 0 ; j < Referrals[CurrRefArr[i]].length ; j++){
                CurrLevelReffs[tempLen] = Referrals[CurrRefArr[i]][j];
                tempLen++;
            }
        }
        return (CurrLevelReffs);
    }

   
}