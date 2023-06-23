// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Strings.sol";

interface IPancakeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns(uint256[] memory amounts);
}

contract Avtars is Ownable, ERC721Enumerable {

    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using Strings for uint256;

    address public _token = 0xA07566Db17C9608EB019527b1db3245e59dA33e2; //busd
    address public delegateAddress = 0x1856Cf49B13f3F7EAf3994fD1102347B50222902;
    address public pancakeRouterAdress = 0x8954AfA98594b838bda56FE4C12a09D7739D179b;
    address public token0 = 0xA07566Db17C9608EB019527b1db3245e59dA33e2; //busd
    address public token1 = 0x3f51572a38Bef2Df723D1669393c30Dac3BF4DdE; //evc

    uint256[8] costs = [100 ether, 500 ether, 1000 ether, 2500 ether, 5000 ether, 10000 ether, 25000 ether, 50000 ether];
    uint256[8] public NFT_Quantities = [10, 10, 10, 10, 10, 10, 10, 10];
    uint256[8] testcost = [100 ether, 200 ether, 300 ether, 400 ether, 500 ether, 600 ether, 700 ether, 800 ether];

    string public baseExtension = ".json";
    string public baseURI = "ipfs://QmZLfZHMA5bXDPWRAeMvBAGokxgm1rF2DbgyrFrTfeoAv4/";

    bool public paused = false;
    bool public delegate = false;

    event directReferralRewardTransferred(address user, address directReferrer, uint256 rewardAmount);
    event indirectReferralRewardTransferred(address user, address indirectReferrer, uint256 rewardAmount);

    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public referralCount;
    mapping(address => address) myReferrer;
    mapping(address => address[]) referrals;
    mapping(address => bool)[8] public hasTokens;
    mapping(address => mapping(uint256 => uint256)) public mintUserDetails;
    mapping(address => uint256) public userInvestment;
    mapping(address => uint256) public joinTimestamp;
    mapping(address => setRank) setUserRank;

    struct AddressRank {
        address referrer;
        uint256 rank;
        uint256 percentage;
    }

    struct setRank {
        uint256 _rank;
        bool _rankChanged;
    }

    struct teamStatistic {
        address _user;
        uint256 _rank;
        uint256 _totalPartners;
        string nftLevel;
        uint256 totalTeamSales;
    }

    Counters.Counter[8] public NFT_Counters;

    //Constructor
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        NFT_Counters[1]._value = 20;
        NFT_Counters[2]._value = 30;
        NFT_Counters[3]._value = 40;
        NFT_Counters[4]._value = 50;
        NFT_Counters[5]._value = 60;
        NFT_Counters[6]._value = 70;
        NFT_Counters[7]._value = 80;
    }

    //User
    function mintNFT(uint256 _level, uint256 _mintPrice, bool _delegate, address _referrer) public { //can use this after testing
        uint256 level = _level - 1;
        require(level >= 0 && level <= 7, "Invalid NFT level");
        require(!hasTokens[level][msg.sender], "You already have an NFT of this level!");
        require(!paused, "Minting is paused");
        require(totalSupplyOfLevel(_level) < NFT_Quantities[level], "Cannot mint more NFTs of this level");
        setReferrer(_referrer); // constant referrer
        uint256 requiredPrice = costs[level];
        if (msg.sender != owner() && !whitelisted[msg.sender]) {
            address directReferrer = _referrer;
            address indirectReferrer = getMyReferrer(_referrer);
            uint256 directReferralReward = requiredPrice / 10;
            uint256 indirectReferralReward = requiredPrice * 5 / 100;
            if (_delegate) {
                uint256 sharePrice = requiredPrice * 10 / 100;
                uint256 newMintPrice = requiredPrice + sharePrice;
                require(_mintPrice >= newMintPrice, "Insufficient payment amount; if delegate is true, add 10% more.");
                uint256 shareToDelegate = _mintPrice - requiredPrice;
                if (indirectReferrer != address(0)) {
                    IERC20(_token).safeTransferFrom(msg.sender, address(this), _mintPrice);
                    IERC20(_token).transfer(delegateAddress, shareToDelegate);
                    IERC20(_token).transfer(indirectReferrer, indirectReferralReward);
                    IERC20(_token).transfer(directReferrer, directReferralReward);
                    emit indirectReferralRewardTransferred(msg.sender, indirectReferrer, indirectReferralReward);
                } else if (directReferrer != address(0)) {
                    IERC20(_token).safeTransferFrom(msg.sender, address(this), _mintPrice);
                    IERC20(_token).transfer(delegateAddress, shareToDelegate);
                    IERC20(_token).transfer(directReferrer, directReferralReward);
                    emit directReferralRewardTransferred(msg.sender, directReferrer, directReferralReward);
                }
            } else {
                require(_mintPrice >= requiredPrice, "Insufficient payment amount");
                if (indirectReferrer != address(0)) {
                    IERC20(_token).safeTransferFrom(msg.sender, address(this), _mintPrice);
                    IERC20(_token).transfer(indirectReferrer, indirectReferralReward);
                    IERC20(_token).transfer(directReferrer, directReferralReward);
                    emit directReferralRewardTransferred(msg.sender, directReferrer, directReferralReward);
                    emit indirectReferralRewardTransferred(msg.sender, indirectReferrer, indirectReferralReward);
                } else if (directReferrer != address(0)) {
                    IERC20(_token).safeTransferFrom(msg.sender, address(this), _mintPrice);
                    IERC20(_token).transfer(directReferrer, directReferralReward);
                    emit directReferralRewardTransferred(msg.sender, directReferrer, directReferralReward);
                } else {
                    IERC20(_token).safeTransferFrom(msg.sender, address(this), _mintPrice);
                }
            }
        }
        busdAndEvcRB(msg.sender, requiredPrice);
        NFT_Counters[level].increment();
        uint256 tokenId = NFT_Counters[level].current();
        userInvestment[msg.sender] += requiredPrice;
        _safeMint(msg.sender, tokenId);
        hasTokens[level][msg.sender] = true;
        mintUserDetails[msg.sender][_level] = block.timestamp;
    }

    function busdAndEvcRB(address _user, uint256 _mintAmount) public {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        uint256 deadline = block.timestamp + 5000;
        AddressRank[] memory referralBonusList = getUserRankBonus(_user);
        IERC20(token0).approve(pancakeRouterAdress, _mintAmount);
        for (uint256 i = 0; i < referralBonusList.length; i++) {
            address referrer = referralBonusList[i].referrer;
            uint256 percentageTransfer = referralBonusList[i].percentage;
            uint256 transferableAmount = (_mintAmount * percentageTransfer) / 100;
            uint256 evcTransferAmount = (transferableAmount * 25) / 100;
            uint256 busdTransferAmount = (transferableAmount * 75) / 100;
            IPancakeRouter(pancakeRouterAdress).swapExactTokensForTokens(evcTransferAmount, 0, path, referrer, deadline);
            IERC20(_token).transfer(referrer, busdTransferAmount);
        }
    }

    //View
    function checkUserRank(address _user) public view returns(uint256 _rank) { //can use this after testing
        if (setUserRank[_user]._rankChanged) {
            return setUserRank[_user]._rank;
        }
        uint256 teamsale = getTeamSaleVolume(_user);
        if (hasTokens[6][_user] && teamsale >= 700 ether && getRankUplifting(_user, 5, 5)) {
            return 7;
        }
        if (hasTokens[5][_user] && teamsale >= 600 ether && getRankUplifting(_user, 4, 4)) {
            return 6;
        }
        if (hasTokens[4][_user] && teamsale >= 500 ether && getRankUplifting(_user, 3, 3)) {
            return 5;
        }
        if (hasTokens[3][_user] && teamsale >= 400 ether && getRankUplifting(_user, 2, 2)) {
            return 4;
        }
        if (hasTokens[2][_user] && teamsale >= 300 ether && getRankUplifting(_user, 1, 1)) {
            return 3;
        }
        if (hasTokens[1][_user] && teamsale >= 200 ether && getRankUplifting(_user, 0, 0)) {
            return 2;
        }
        if (hasTokens[0][_user] && teamsale >= 100 ether) {
            return 1;
        }
    }

    function getMyReferrer(address _user) public view returns(address) {
        return myReferrer[_user];
    }

    function getNFTCost(uint256 _level) public view returns(uint256) {
        uint256 level = _level - 1;
        return costs[level];
    }

    function getRankUplifting(address _user, uint256 nftlevel, uint256 amount) public view returns(bool) { //can use this after testing
        uint256 memberrankCount;
        bool staisfied;
        for (uint256 i = 0; i < referrals[_user].length; i++) {
            address member = referrals[_user][i];
            if (setUserRank[member]._rankChanged == true && setUserRank[member]._rank > nftlevel) {
                memberrankCount++;
                staisfied = true;
            } else if (getAdminRankChanged(member, nftlevel)) {
                memberrankCount++;
                staisfied = true;
            } else if (hasTokens[nftlevel][member]) {
                if (getTeamSaleVolume(member) >= testcost[amount]) {
                    if (amount == 0) {
                        memberrankCount++;
                        staisfied = true;
                        if (setUserRank[member]._rankChanged == true && setUserRank[member]._rank <= nftlevel) {
                            memberrankCount--;
                            staisfied = false;
                        }
                    } else {
                        uint256 newNftlevel = nftlevel - 1;
                        uint256 newamount = amount - 1;
                        if (getRankUplifting(member, newNftlevel, newamount)) {
                            memberrankCount++;
                            staisfied = true;
                            if (setUserRank[member]._rankChanged == true && setUserRank[member]._rank <= nftlevel) {
                                memberrankCount--;
                                staisfied = false;
                            }
                        }
                    }
                }
            }
            if (memberrankCount < 3 && !staisfied) {

                if (getTeamSaleVolume(member) >= testcost[amount]) {
                    bool found = legSearch(member, nftlevel, amount);
                    if (found == true) {
                        memberrankCount++;
                    }
                }
            }

            if (memberrankCount >= 3) {
                return true;
            }
        }

        return false;
    }

    function getReferrals(address referrer) public view returns(address[] memory) {
        return referrals[referrer];
    }

    function getTeamSaleVolume(address user) public view returns(uint256) {
        address[] memory _referrals = referrals[user];
        uint256 totalInvestment = 0;
        uint256 memberinvestment;
        for (uint256 i = 0; i < _referrals.length; i++) {
            address member = _referrals[i];
            totalInvestment += userInvestment[member];
            if (referrals[member].length > 0) {
                memberinvestment = getTeamSaleVolume(member);
                totalInvestment += memberinvestment;
            }
        }
        return totalInvestment;
    }

    function getTotalPartners(address _user) public view returns(uint256) {
        address[] memory _referrals = referrals[_user];
        uint256 totalPartners;
        if (_referrals.length > 0) {
            totalPartners += _referrals.length;
            for (uint256 i = 0; i < _referrals.length; i++) {
                uint256 partnersTotal = getTotalPartners(_referrals[i]);
                totalPartners += partnersTotal;
            }
        }
        return totalPartners;
    }

    function getUserRankBonus(address _user) public view returns(AddressRank[] memory) {
        address referrer = myReferrer[_user];
        uint256 referrersCount = 0;
        while (referrer != address(0)) {
            referrersCount++;
            referrer = myReferrer[referrer];
        }
        AddressRank[] memory addressRanks = new AddressRank[](referrersCount);
        referrer = myReferrer[_user];
        uint256 userRank = checkUserRank(referrer);
        uint256 index = 0;
        uint256 previousRank = 0;
        for (uint256 i = 0; i < referrersCount; i++) {
            uint256 rank = checkUserRank(referrer);
            if (rank >= userRank && rank > previousRank) {
                uint256 percentage = (rank - previousRank) * 4;
                addressRanks[index] = AddressRank(referrer, rank, percentage);
                index++;
                previousRank = rank;
            }
            referrer = myReferrer[referrer];
        }
        AddressRank[] memory finalAddressRanks = new AddressRank[](index);
        for (uint256 i = 0; i < index; i++) {
            finalAddressRanks[i] = addressRanks[i];
        }
        return finalAddressRanks;
    }

    function recentlyJoined(address _account) public view returns(address[] memory) {
        address[] memory teamAddresses = filterFunction(_account);
        uint256[] memory joinTimestamps = new uint256[](teamAddresses.length);
        if (teamAddresses.length == 0) {
            return teamAddresses;
        }
        for (uint256 i = 0; i < teamAddresses.length; i++) {
            joinTimestamps[i] = joinTimestamp[teamAddresses[i]];
        }
        sortAddressesByTimestamp(teamAddresses, joinTimestamps);
        uint256 arrayLength = teamAddresses.length > 0 ? teamAddresses.length : 0;
        uint256 resultLength = arrayLength > 10 ? 10 : arrayLength;
        address[] memory addressesToReturn = new address[](resultLength);
        for (uint256 i = 0; i < resultLength; i++) {
            addressesToReturn[i] = teamAddresses[arrayLength - i - 1];
        }
        return addressesToReturn;
    }

    function teamSalesInformation(address _user) public view returns(teamStatistic[] memory) {
        address[] memory _referrals = referrals[_user];
        teamStatistic[] memory teamStatisticsArray = new teamStatistic[](_referrals.length);
        for (uint256 i = 0; i < _referrals.length; i++) {
            address user = _referrals[i];
            uint256 userRank = checkUserRank(user);
            uint256 Totalpartner = getTotalPartners(user);
            uint256 teamTurnover = getTeamSaleVolume(user);
            string memory ownNFT;
            if (hasTokens[7][user]) {
                ownNFT = "CryptoCap Tycoon";
            } else if (hasTokens[6][user]) {
                ownNFT = "Bitcoin Billionaire";
            } else if (hasTokens[5][user]) {
                ownNFT = "Blockchain Mogul";
            } else if (hasTokens[4][user]) {
                ownNFT = "Crypto King";
            } else if (hasTokens[3][user]) {
                ownNFT = "Crypto Investor";
            } else if (hasTokens[2][user]) {
                ownNFT = "Crypto Entrepreneur";
            } else if (hasTokens[1][user]) {
                ownNFT = "Crypto Enthusiast";
            } else if (hasTokens[0][user]) {
                ownNFT = "Crypto Newbies";
            }
            teamStatistic memory teamStatisticsInfo = teamStatistic(user, userRank, Totalpartner, ownNFT, teamTurnover);
            teamStatisticsArray[i] = teamStatisticsInfo;
        }
        return teamStatisticsArray;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns(string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }

    function totalSupplyOfLevel(uint256 _level) public view returns(uint256) {
        uint256 total = NFT_Counters[_level - 1].current();
        if (_level > 1 && _level <= 8) {
            uint256 deduction = (_level) * 10;
            return total - deduction;
        } else {
            return total;
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    //Internal
    function filterFunction(address _account) internal view returns(address[] memory) {
        address[] memory filterarray = getTeamAddresses(_account);
        address[] memory teamAddressesWithoutFirst = new address[](filterarray.length - 1);
        for (uint256 i = 0; i < filterarray.length - 1; i++) {
            teamAddressesWithoutFirst[i] = filterarray[i + 1];
        }
        return teamAddressesWithoutFirst;
    }

    function getAdminRankChanged(address user, uint256 _rank) internal view returns(bool) {
        address[] memory _referrals = referrals[user];
        // uint256 totalInvestment = 0;
        for (uint256 i = 0; i < _referrals.length; i++) {
            address member = _referrals[i];
            if (setUserRank[member]._rankChanged == true && setUserRank[member]._rank > _rank) {
                return true;
            }
            if (referrals[member].length > 0) {
                if (getAdminRankChanged(member, _rank)) {
                    return true;
                }
            }
        }
        return false;
    }

    function getTeamAddresses(address _user) internal view returns(address[] memory) {
        address[] memory teamAddresses = new address[](1);
        teamAddresses[0] = _user;
        uint256 numReferrals = referrals[_user].length;
        for (uint256 i = 0; i < numReferrals; i++) {
            address member = referrals[_user][i];
            address[] memory memberTeam = getTeamAddresses(member);
            address[] memory concatenated = new address[](teamAddresses.length + memberTeam.length);
            for (uint256 j = 0; j < teamAddresses.length; j++) {
                concatenated[j] = teamAddresses[j];
            }
            for (uint256 j = 0; j < memberTeam.length; j++) {
                concatenated[teamAddresses.length + j] = memberTeam[j];
            }
            teamAddresses = concatenated;
        }
        return teamAddresses;
    }

    function legSearch(address member, uint256 nftlevel, uint256 amount) internal view returns(bool) { //can use this after testing
        if (referrals[member].length == 0) {
            return false;
        }
        for (uint256 i = 0; i < referrals[member].length; i++) {
            address referrer = referrals[member][i];
            if (setUserRank[referrer]._rankChanged == true && setUserRank[referrer]._rank > nftlevel) {
                return true;
            } else if (setUserRank[referrer]._rankChanged == false) {
                if (hasTokens[nftlevel][referrer]) {
                    if (getTeamSaleVolume(referrer) >= testcost[amount]) {
                        if (amount == 0) {
                            return true;
                        } else {
                            uint256 newNftlevel = nftlevel - 1;
                            uint256 newamount = amount - 1;
                            if (getRankUplifting(referrer, newNftlevel, newamount)) {
                                return true;
                            }
                        }
                    }
                }
            }
            if (legSearch(referrer, nftlevel, amount)) {
                return true;
            }
        }
        return false;
    }

    function setReferrer(address referrer) internal {
        if (myReferrer[msg.sender] == address(0)) {
            require(referrer != msg.sender, "Cannot refer yourself");
            myReferrer[msg.sender] = referrer;
            referrals[referrer].push(msg.sender);
            referralCount[referrer]++;
            joinTimestamp[msg.sender] = block.timestamp; // Record the join timestamp
        } else if (myReferrer[msg.sender] != address(0)) {
            require(myReferrer[msg.sender] == referrer, "fill correct reffral address");
        }
    }

    function sortAddressesByTimestamp(address[] memory addressesArr, uint256[] memory timestampsArr) internal pure {
        uint256 n = addressesArr.length;
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = i + 1; j < n; j++) {
                if (timestampsArr[i] > timestampsArr[j]) {
                    (addressesArr[i], addressesArr[j]) = (addressesArr[j], addressesArr[i]);
                    (timestampsArr[i], timestampsArr[j]) = (timestampsArr[j], timestampsArr[i]);
                }
            }
        }
    }

    //Admin
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setCost(uint256[] memory newCosts) public onlyOwner {
        require(newCosts.length == 8, "Invalid number of cost values");
        for (uint256 i = 0; i < newCosts.length; i++) {
            costs[i] = newCosts[i];
        }
    }

    function setDelegateAddress(address _delegateAddress) public onlyOwner {
        delegateAddress = _delegateAddress;
    }

    function setpancakeRouterAdress(address _newpancakeRouterAdress) public onlyOwner {
        pancakeRouterAdress = _newpancakeRouterAdress;
    }

    function setToken(address _newtoken) public onlyOwner {
        _token = _newtoken;
    }

    function setToken0(address _newtoken0) public onlyOwner {
        token0 = _newtoken0;
    }

    function setToken1(address _newtoken1) public onlyOwner {
        token1 = _newtoken1;
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }

    function withdraw() public payable onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    //
    function changeInvestment(address _user, uint256 _value) public onlyOwner {
        userInvestment[_user] = _value;
    }

    function changeRank(address _user, uint256 _newrank, bool _change) public onlyOwner {
        require(_newrank <= 7, "rank cannot be more than 7");
        setUserRank[_user]._rank = _newrank;
        setUserRank[_user]._rankChanged = _change;
    }

    function createReferralArray(address _ref, address[] memory to) public onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            address user = to[i];
            referrals[_ref].push(user);
            myReferrer[user] = _ref;
            joinTimestamp[user] = block.timestamp; // Record the join timestamp
        }
    }

    function setNftLevel(address _useradd, uint256 _level) public onlyOwner {
        require(_level >= 1 && _level <= 8, "Invalid NFT level");
        uint8 nftIndex = uint8(_level - 1);
        hasTokens[nftIndex][_useradd] = true;
    }

}