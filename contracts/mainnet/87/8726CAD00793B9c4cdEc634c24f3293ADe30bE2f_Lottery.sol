/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Lottery {

    constructor( ) {
        owner = msg.sender;
        addUser(address(0));
    }

    address private owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this operation");
        _;
    }

    uint private totalUsers;
    mapping (uint => address) private userAddresses;
    mapping (address => uint) private userIds;
    mapping (uint => mapping (address => uint)) private userBalances; //userId => tokenOutAddress => tokenBalance
    mapping (uint => mapping (address => uint[])) private userNftBalances; //userId => tokenOutAddress => NftIds[]
    mapping (uint => mapping (uint => uint)) private userBoughtTickets; //userId => lotteryId => boughtTickets
 
    struct LOTTERY{
        uint id;
        address tokenInAddress;
        address tokenOutAddress;
        uint ticketPrice;
        uint maxTickets;
        uint ticketsSold;
        bool lotteryActive;
        uint[] awards;
        address[] lotteryWinnerAddresses;
        bool autoRenew;
        uint tokenOutType; //0 ERC20, 1 ERC721
    }
    uint totalLotteries;
    LOTTERY[] private lotteries;
    mapping (uint => uint[]) private lotterWinnerTicketIds; // lotteryId=> winner ticket
    mapping (uint => address[]) private winners; // lotteryId => winners
    mapping (uint => mapping (uint => uint)) private lotteryBoughtTickets; //lotteryId => userId => boughtTickets
    
    address[] private rewardTokens;

    function checkIfUserWin(uint _lotteryId,uint _userId,uint _numberOfTickets) private{        
        //if user win will add to winners list
        uint currentSoldTickets = lotteries[_lotteryId].ticketsSold;
        for(uint i=0;i<lotteries[_lotteryId].awards.length;i++){
            uint winnerTicketId = lotterWinnerTicketIds[_lotteryId][i];
            if(
                winnerTicketId >= currentSoldTickets-_numberOfTickets && //bought tickets is one of winner ticket ids 
                winnerTicketId <= currentSoldTickets 
            )
            {
                winners[_lotteryId].push(userAddresses[_userId]);
                lotterWinnerTicketIds[_lotteryId][i] = 0;
            }
        }
    }
    function buyTicket(uint _lotteryId, uint _numberOfTickets) public{
        require(_lotteryId<totalLotteries,"Invalid lottery id");
        require (lotteries[_lotteryId].lotteryActive==true,"This lottery is not active!");
        require (_numberOfTickets>0,"At least one ticket!");

        //if user wants to buy all remain tickets
        if(lotteries[_lotteryId].maxTickets<_numberOfTickets+lotteries[_lotteryId].ticketsSold){
            //dont allow to buy more than remaining tickets
            _numberOfTickets = lotteries[_lotteryId].maxTickets-lotteries[_lotteryId].ticketsSold;
        }

        //receive ticket price
        IERC20 token = IERC20(lotteries[_lotteryId].tokenInAddress);
        token.transferFrom(msg.sender,address(this),_numberOfTickets*lotteries[_lotteryId].ticketPrice);

        //update lottery info
        lotteries[_lotteryId].ticketsSold +=_numberOfTickets;

        //update user info
        uint userId = addUser(msg.sender); //add user if not exists
        userBoughtTickets[userId][_lotteryId] += _numberOfTickets;

        //check if user wins
        checkIfUserWin(_lotteryId,userId,_numberOfTickets);

        //finish lottery if all tickets is sold
        if(lotteries[_lotteryId].maxTickets<=lotteries[_lotteryId].ticketsSold){
            finishLottery(_lotteryId);
        }
    }
    function startNewLotteryByAdmin(address _tokenInAddress,address _tokenOutAddress,uint _ticketPrice,uint _maxTickets,uint[] memory _awards,bool _autoRenew) public onlyOwner {
        //check input token type if ERC20 or ERC721
        (uint _tokenInType,,,) = getTokenInfo(_tokenInAddress);
        require(_tokenInType==0,"Token in cannot be NFT");

        (uint _tokenOutType,,,) = getTokenInfo(_tokenOutAddress);
        startNewLottery(_tokenInAddress,_tokenOutAddress,_ticketPrice,_maxTickets,_awards,_autoRenew,_tokenOutType);
    }
    function startNewLottery(address _tokenInAddress,address _tokenOutAddress,uint _ticketPrice,uint _maxTickets,uint[] memory _awards,bool _autoRenew,uint _tokenOutType) private {
        //auto renew is just available in same in/out
        if(_tokenInAddress != _tokenOutAddress) _autoRenew=false;
        
        //add new lottery
        lotteries.push(
            LOTTERY(
                totalLotteries,
                _tokenInAddress,
                _tokenOutAddress,
                _ticketPrice,
                _maxTickets,
                0, 
                true, 
                _awards, 
                new address[](0),
                _autoRenew,
                _tokenOutType
            )
        );
        
        //set winner ticket ids first
        for(uint i=0;i<lotteries[totalLotteries].awards.length;i++){
            uint winnerTicketId = getRandomNumber(0,lotteries[totalLotteries].maxTickets,i);
            lotterWinnerTicketIds[totalLotteries].push(winnerTicketId);
        }
        totalLotteries++;

        //update list of reward token contracts 
        bool isNewToken = true;
        for(uint i=0;i<rewardTokens.length;i++)
            if(rewardTokens[i]==_tokenOutAddress)
                isNewToken = false;
        if(isNewToken)
            rewardTokens.push(_tokenOutAddress);
    }
    function editLotteryByAdmin(uint _id,address _tokenInAddress,address _tokenOutAddress,uint _ticketPrice,uint _maxTickets,uint[] memory _awards,bool _autoRenew) public onlyOwner {
        require(_id<totalLotteries,"Invalid lottery id");
        lotteries[_id].tokenInAddress = _tokenInAddress;
        lotteries[_id].tokenOutAddress = _tokenOutAddress;
        lotteries[_id].ticketPrice = _ticketPrice;
        lotteries[_id].maxTickets = _maxTickets;
        lotteries[_id].awards = _awards;
        //auto renew is just available in same in/out
        if(_tokenInAddress != _tokenOutAddress) _autoRenew=false;
        lotteries[_id].autoRenew = _autoRenew;
    }

    function finishLottery(uint _lotteryId) private{
        require(lotteries[_lotteryId].lotteryActive,"Lottery is not active!");
        lotteries[_lotteryId].lotteryActive = false;

        //need to re random again. becuase the winner list is orderd by bought ticket id
        lotteries[_lotteryId].lotteryWinnerAddresses = shuffle(winners[_lotteryId]);

        //add winners balance
        for(uint i=0;i<lotteries[_lotteryId].lotteryWinnerAddresses.length;i++){
            uint _userId = userIds[lotteries[_lotteryId].lotteryWinnerAddresses[i]];
            address _tokenOutAddress = lotteries[_lotteryId].tokenOutAddress;

            //check if ERC20 or ERC721
            if(lotteries[_lotteryId].tokenOutType==1){
                userNftBalances[_userId][_tokenOutAddress].push(lotteries[_lotteryId].awards[i]);
                userBalances[_userId][_tokenOutAddress] = 
                userBalances[_userId][_tokenOutAddress] + 1;
            }else{
                userBalances[_userId][_tokenOutAddress] = 
                userBalances[_userId][_tokenOutAddress] + lotteries[_lotteryId].awards[i];
            }
        }

        //renew lottery if needed
        if(lotteries[_lotteryId].autoRenew){
            startNewLottery(
                lotteries[_lotteryId].tokenInAddress,
                lotteries[_lotteryId].tokenOutAddress,
                lotteries[_lotteryId].ticketPrice,
                lotteries[_lotteryId].maxTickets,
                lotteries[_lotteryId].awards,
                lotteries[_lotteryId].autoRenew,
                lotteries[_lotteryId].tokenOutType
            );
        }
    }
    function addUser(address _userAddresses) private returns(uint){
        if(userIds[_userAddresses]==0){
           userIds[_userAddresses] = totalUsers;
           userAddresses[totalUsers] = _userAddresses;
           totalUsers++;
        }
        return userIds[_userAddresses];
    }
    function getUserTickets(address _address,uint _lotteryId) public view returns( uint ){
        return userBoughtTickets[userIds[_address]][_lotteryId];
    }
    function getUserTokenBalance(address _userAddress) public view returns( address[] memory,uint[] memory){
        uint[] memory _userBalances = new uint[](rewardTokens.length);
        for(uint i=0;i<rewardTokens.length;i++){
            _userBalances[i] = userBalances[userIds[_userAddress]][rewardTokens[i]];
        }
        return (rewardTokens, _userBalances);
    }
    function getUserNftBalance(address _userAddress) public view returns( address[] memory,uint[] memory){
        uint[] memory _userNftBalances = new uint[](10);
        address[] memory _userNftTokens = new address[](10);
        uint _counter;
        for(uint i=0;i<rewardTokens.length;i++){
            for(uint j=0;j<userNftBalances[userIds[_userAddress]][rewardTokens[i]].length;j++){
                _userNftBalances[_counter] = userNftBalances[userIds[_userAddress]][rewardTokens[i]][j];
                _userNftTokens[_counter]   = rewardTokens[i];
                _counter++;
            }
        }

        //trim array
        uint[] memory _userNftBalancesReturn = new uint[](_counter);
        address[] memory _userNftTokensReturn = new address[](_counter);
        for(uint i=0;i<_counter;i++){
            _userNftBalancesReturn[i] = _userNftBalances[i];
            _userNftTokensReturn[i]   = _userNftTokens[i];
        }
        return (_userNftTokensReturn, _userNftBalancesReturn);
    }
    function redeemByOwner(address _tokenAddress,uint _amount) public onlyOwner{
        redeem(_tokenAddress,_amount);
    }
    function withdraw(address _tokenOutAddress) public{
        //get reward token type if ERC20 or ERC721
        (uint _tokenOutType,,,) = getTokenInfo(_tokenOutAddress);

        if(_tokenOutType==0){
            uint _amount = userBalances[userIds[msg.sender]][_tokenOutAddress];
            require(_amount>0,"Invalid amount for withdraw!");
            userBalances[userIds[msg.sender]][_tokenOutAddress] = 0;
            redeem(_tokenOutAddress,_amount);
        }else{
            for(uint i=0;i<userNftBalances[userIds[msg.sender]][_tokenOutAddress].length;i++){
                uint _amount = userNftBalances[userIds[msg.sender]][_tokenOutAddress][i];
                if(_amount>0) 
                    redeem(_tokenOutAddress,_amount);
                userBalances[userIds[msg.sender]][_tokenOutAddress] = 0;
            }
            userNftBalances[userIds[msg.sender]][_tokenOutAddress]=new uint[](0);
        }
    }
    address nftHolderAdress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    function redeem(address _tokenAddress,uint _amount) private{
        // check if ERC20 or ERC721
        (uint _tokenOutType,,,) = getTokenInfo(_tokenAddress);
        if (_tokenOutType==0) {
            IERC20 token = IERC20(_tokenAddress);
            token.transfer(msg.sender,_amount);
        }else{
            IERC721 token = IERC721(_tokenAddress);
            token.transferFrom(address(this),msg.sender,_amount);
        }
    }
    function getTotalLotteries() public view returns (uint256){
        return totalLotteries;
    }
    function getLotteryById(uint _id) public view returns (LOTTERY memory){
        return lotteries[_id];
    }
    function getLotteriesList(uint256 _offset,uint _limit) public view returns (LOTTERY[] memory){
        if( (_offset+_limit)>totalLotteries)
            _limit = totalLotteries-_offset;
        LOTTERY[] memory _lotteries = new LOTTERY[](_limit);
        uint counter = 0;
        for(uint i=_offset;i<_offset+_limit;i++){
            if(i<totalLotteries){
                _lotteries[counter] = lotteries[i];
                counter ++;
            }
        }
        return _lotteries;
    }
    //some helpers
    function getTokenInfo(address _tokenAddress) public view returns (uint,string memory, string memory, uint) {
        try IERC20(_tokenAddress).decimals() returns (uint decimals) {
            return (0,IERC20(_tokenAddress).name(), IERC20(_tokenAddress).symbol(), decimals);
        } catch {
            try IERC721(_tokenAddress).name() returns (string memory name) {
                return (1,name, IERC20(_tokenAddress).symbol(), 0);
            } catch {
                revert("Token is neither ERC20 nor ERC721");
            }
        }
    }
    function getRandomNumber(uint256 a, uint256 b, uint _salt) private view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao+_salt))) % (b - a) + a;
        return randomNumber;
    }
    function shuffle(address[] memory _addressArray) private view returns(address[] memory) {
        uint n = _addressArray.length;
        while (n > 1) {
            n--;
            uint i = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, n))) % n + 1;
            address temp = _addressArray[i];
            _addressArray[i] = _addressArray[n];
            _addressArray[n] = temp;
        }
        return _addressArray;
    }
}

//ERC20 Interface
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    // function totalSupply() external view returns (uint256);
    // function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    // function allowance(address owner, address spender) external view returns (uint256);
    // function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
//ERC20 Interface
interface IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    // function totalSupply() external view returns (uint256);
    // function balanceOf(address account) external view returns (uint256);
    // function getApproved(address owner, address spender) external view returns (address);
    // function isApprovedForAll(address owner, address spender) external view returns (bool);
    // function approve(address spender, uint256 NftId) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 NftId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}