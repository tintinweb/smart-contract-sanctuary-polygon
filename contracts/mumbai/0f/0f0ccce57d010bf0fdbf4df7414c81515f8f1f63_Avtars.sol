// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeERC20.sol";

contract Avtars is Ownable, ERC721Enumerable {

    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeERC20 for IERC20;

    address public _token = 0x3ed64D74A7191f404d53eddAC90cCb66Ee42e45C; //busd
    address public delegateAddress = 0x1856Cf49B13f3F7EAf3994fD1102347B50222902;

    uint256[8] costs = [100 ether, 500 ether, 1000 ether, 2500 ether, 5000 ether, 10000 ether, 25000 ether, 50000 ether];
    uint256[8] public NFT_Quantities = [10, 10, 10, 10, 10, 10, 10, 10];
    uint256[] public NFTidArray;
    uint256[8] testcost = [100 ether, 200 ether, 300 ether, 400 ether, 500 ether, 600 ether, 700 ether,800 ether];

    string public baseExtension = ".json";
    string public baseURI = "ipfs://QmZLfZHMA5bXDPWRAeMvBAGokxgm1rF2DbgyrFrTfeoAv4/";

    bool public paused = false;
    bool public delegate = false;

    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public referralRank;
    mapping(address => address) myReferrer;
    mapping(address => address[]) referrals;
    mapping(address => bool)[8] public hasTokens;
    mapping(address => uint) public userInvestment;
    mapping(uint256 => RankCondition) public rankConditions;
    mapping(address => uint256) public joinTimestamp;

    struct teamStatistic {
        address _user;
        uint _rank;
        uint _totalPartners;
        string nftLevel;
        uint totalTeamSales;
    }

    struct RankCondition {
        uint256 minTeamSale;         // Minimum team sale volume required
        uint256 prevRank;            // Previous rank required
        uint256 prevRankMinTeamSale; // Minimum team sale volume required for the previous rank
        uint256 newRank;             // New rank to be assigned
    }

    struct setRank{
        uint _rank;
        bool _rankChanged;
    }
    mapping (address => setRank) setUserRank;

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


        rankConditions[7] = RankCondition(700 ether, 6, 600 ether, 7);
        rankConditions[6] = RankCondition(600 ether, 5, 500 ether, 6);
        rankConditions[5] = RankCondition(500 ether, 4, 400 ether, 5);
        rankConditions[4] = RankCondition(400 ether, 3, 300 ether, 4);
        rankConditions[3] = RankCondition(300 ether, 2, 200 ether, 3);
        rankConditions[2] = RankCondition(200 ether, 1, 100 ether, 2);
        rankConditions[1] = RankCondition(100 ether, 0, 0, 1);
    }

    //User
    function mintNFT(uint _level, uint _mintPrice, bool _delegate, address _referrer) public {
        uint level = _level - 1;
        require(level >= 0 && level <= 7, "Invalid NFT level");
        require(!hasTokens[level][msg.sender], "You already have an NFT of this level!");
        require(!paused, "Minting is paused");
        require(totalSupplyOfLevel(_level) < NFT_Quantities[level], "Cannot mint more NFTs of this level");
        setReferrer(_referrer); // constant referrer
        if (msg.sender != owner()) {
            if (!whitelisted[msg.sender]) {
                uint requiredPrice = costs[level];
                require(_mintPrice >= requiredPrice, "Insufficient payment amount");
                if (_delegate == true) {
                    uint sharePrice = requiredPrice * 10 / 100;
                    uint newMintPrice = requiredPrice + sharePrice;
                    require(_mintPrice >= newMintPrice, "Insufficient payment amount; if delegate is true, add 10% more.");
                    uint256 transferValue = _mintPrice - requiredPrice - sharePrice;
                    uint shareToDelegate = sharePrice + transferValue;
                    IERC20(_token).safeTransferFrom(msg.sender, address(this), requiredPrice);
                    IERC20(_token).safeTransferFrom(msg.sender, delegateAddress, shareToDelegate);
                } else {
                    IERC20(_token).safeTransferFrom(msg.sender, address(this), _mintPrice);
                }
            }
        }
        NFT_Counters[level].increment();
        uint256 tokenId = NFT_Counters[level].current();
        NFTidArray.push(tokenId);
        userInvestment[msg.sender] += _mintPrice;
        _safeMint(msg.sender, tokenId);
        hasTokens[level][msg.sender] = true;
        rankUpdate();
    }

     function rankupLifting(address _user) public {
        uint256 rank =  getRankupLifting2(_user);
        referralRank[_user] = rank;
    }

    //View
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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

    function getMyReferrer(address _user) public view returns(address) {
        return myReferrer[_user];
    }

    function getReferrals(address referrer) public view returns(address[] memory) {
        return referrals[referrer];
    }

    function getTeamSaleVolume(address user) public view returns(uint) {
        address[] memory _referrals = referrals[user];
        uint totalInvestment = 0;
        uint memberinvestment;
        for (uint i = 0; i < _referrals.length; i++) {
            address member = _referrals[i];
            totalInvestment += userInvestment[member];
            if (referrals[member].length > 0) {
                memberinvestment = getTeamSaleVolume(member);
                totalInvestment += memberinvestment;
            }
        }
        return totalInvestment;
    }

    function getNFTCost(uint _level) public view returns(uint) {
        uint level = _level - 1;
        return costs[level];
    }

    // function getRankupLifting(address _user) public view returns(uint rank) {
    //     uint teamsale = getTeamSaleVolume(_user);
    //     for (uint i = 7; i >= 1; i--) {
    //         RankCondition memory condition = rankConditions[i];
    //         if (hasTokens[i-1][_user] && teamsale >= condition.minTeamSale && checkRank(_user, condition.prevRank, condition.prevRankMinTeamSale)) {
    //             return condition.newRank;
    //         }
            
    //     }
    // }

    function getRankupLifting(address _user) public view returns (uint rank) {
         if(setUserRank[_user]._rankChanged){
            return setUserRank[_user]._rank;
        }
        uint teamsale = getTeamSaleVolume(_user);
               
        for (uint i = 7; i >=2 ; i--) {
            RankCondition memory condition = rankConditions[i];
            if (hasTokens[i-1][_user] && teamsale >= condition.minTeamSale && checkRank(_user, i-2, i-2)) {
                return condition.newRank;
            }
        }
         // Check conditions for rank 1 separately
        if (hasTokens[0][_user] && teamsale >= rankConditions[1].minTeamSale) {
            return rankConditions[1].newRank;
        }
        // Return 0 if none of the rank conditions are met
        return 0;
    }


    function getRankupLifting2(address _user) public view returns (uint _rank) {
        if(setUserRank[_user]._rankChanged){
            return setUserRank[_user]._rank;
        }
        uint teamsale = getTeamSaleVolume(_user);
        if (hasTokens[6][_user] && teamsale >= 700 ether && checkRank(_user, 5, 5)) {
            return 7;
        }
        if (hasTokens[5][_user] && teamsale >= 600 ether && checkRank(_user, 4, 4)) {
            return 6;
        }
        if (hasTokens[4][_user] && teamsale >= 500 ether && checkRank(_user, 3, 3)) {
            return 5;
        }
        if (hasTokens[3][_user] && teamsale >= 400 ether && checkRank(_user, 2, 2)) {
            return 4;
        }
        if (hasTokens[2][_user] && teamsale >= 300 ether && checkRank(_user, 1, 1)) {
            return 3;
        }
        if (hasTokens[1][_user] && teamsale >= 200 ether && checkRank(_user, 0, 0)) {
            return 2;
        }
        if (hasTokens[0][_user] && teamsale >= 100 ether) {
            return 1;
        }
    }

    function checkRank(address _user, uint nftlevel, uint amount) public view returns (bool) {
        address[] memory _referrals = referrals[_user];
        uint memberrankCount;
        uint[8] memory testCost = testcost;
        uint targetCost = testCost[amount];
        for (uint i = 0; i < _referrals.length; i++) {
            address member = _referrals[i];
            uint memberTeamSale = getTeamSaleVolume(member);
            if (hasTokens[nftlevel][member] && memberTeamSale >= targetCost) {
                memberrankCount++;
                if (memberrankCount >= 3) {
                    return true;
                }
            }
            if (memberrankCount < 3 && memberTeamSale >= targetCost) {
                bool found = legSearch(member, nftlevel, amount);
                if (found) {
                    memberrankCount++;
                    if (memberrankCount >= 3) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function getTotalPartners(address _user) public view returns(uint) {
        address[] memory _referrals = referrals[_user];
        uint totalPartners;
        if (_referrals.length > 0) {
            totalPartners += _referrals.length;
            for (uint i = 0; i < _referrals.length; i++) {
                uint partnersTotal = getTotalPartners(_referrals[i]);
                totalPartners += partnersTotal;
            }
        }
        return totalPartners;
    }

    function teamSalesINformation(address _user) public view returns(teamStatistic[] memory) {
        address[] memory _referrals = referrals[_user];
        teamStatistic[] memory teamStatisticsArray = new teamStatistic[](_referrals.length);
        for (uint256 i = 0; i < _referrals.length; i++) {
            address user = _referrals[i];
            uint256 userRank = referralRank[user];
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

    //Internal
    function rankUpdate() internal {
        for (uint i = 0; i < NFTidArray.length; i++) {
            address owner = ERC721.ownerOf(NFTidArray[i]);
            rankupLifting(owner);
        }
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


    function legSearch(address member, uint nftlevel, uint amount) internal view returns (bool) {
        address[] memory _referrals = referrals[member];
        if (referrals[member].length == 0) {
            return false;
        }
        uint[8] memory testCost = testcost;
        uint targetCost = testCost[amount];
        for (uint i = 0; i < _referrals.length; i++) {
            address referrer = _referrals[i];
            uint referrerTeamSale = getTeamSaleVolume(referrer);
            if (hasTokens[nftlevel][referrer] && referrerTeamSale >= targetCost) {
                if (amount == 0) {
                    return true;
                }
                uint newNftlevel = nftlevel - 1;
                uint newAmount = amount - 1;
                if (checkRank(referrer, newNftlevel, newAmount)) {
                    return true;
                }
            }
            if (legSearch(referrer, nftlevel, amount)) {
                return true;
            }
        }
        return false;
    }

    //Admin
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setCost(uint256[] memory newCosts) public onlyOwner {
        require(newCosts.length == 8, "Invalid number of cost values");
        for (uint256 i = 0; i < newCosts.length; i++) {
            costs[i] = newCosts[i];
        }
    }

    function setToken(address _newtoken) public onlyOwner {
        _token = _newtoken;
    }

    function setDelegateAddress(address _delegateAddress) public onlyOwner {
        delegateAddress = _delegateAddress;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }

    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function withdraw() public payable onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    function createReffralarray(address _ref, address[] memory to) public onlyOwner {
        for (uint i = 0; i < to.length; i++) {
            referrals[_ref].push(to[i]);
            joinTimestamp[to[i]] = block.timestamp; // Record the join timestamp
        }
    }

    function changeRank(address _user, uint _newrank, bool _change) public onlyOwner {
        require(_newrank <= 7, "rank cannot be more than 7");
        setUserRank[_user]._rank = _newrank;
        setUserRank[_user]._rankChanged = _change;
    }

    function changeinvestment(address _user, uint _value) public onlyOwner {
        userInvestment[_user] = _value;
    }

    function setNftLevel(address _useradd, uint _level) public onlyOwner {
        require(_level >= 1 && _level <= 8, "Invalid NFT level");
        uint8 nftIndex = uint8(_level - 1);
        hasTokens[nftIndex][_useradd] = true;
    }


    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////recentjoined
    function getTeamAddresses(address _user) internal view returns(address[] memory) {
        address[] memory teamAddresses = new address[](1); // Initialize the array with size 1
        teamAddresses[0] = _user; // Add the user's address to the array
        uint numReferrals = referrals[_user].length;
        for (uint i = 0; i < numReferrals; i++) {
            address member = referrals[_user][i];
            // Recursive call to get team addresses of the referral's team
            address[] memory memberTeam = getTeamAddresses(member);
            // Extend the size of teamAddresses array
            address[] memory concatenated = new address[](teamAddresses.length + memberTeam.length);
            for (uint j = 0; j < teamAddresses.length; j++) {
                concatenated[j] = teamAddresses[j];
            }
            for (uint j = 0; j < memberTeam.length; j++) {
                concatenated[teamAddresses.length + j] = memberTeam[j];
            }
            teamAddresses = concatenated;
        }
        return teamAddresses;
    }

    function recentlyJoined(address _account) public view returns(address[] memory) {
        address[] memory teamAddresses = getTeamAddresses(_account);
        uint256[] memory joinTimestamps = new uint256[](teamAddresses.length);
        for (uint256 i = 0; i < teamAddresses.length; i++) {
            joinTimestamps[i] = joinTimestamp[teamAddresses[i]];
        }
        sortAddressesByTimestamp(teamAddresses, joinTimestamps);
        // Remove the first index (which is the account itself)
        address[] memory result = new address[](teamAddresses.length - 1);
        for (uint256 i = 1; i < teamAddresses.length; i++) {
            result[i - 1] = teamAddresses[i];
        }
        for (uint256 i = 0; i < result.length; i++) {
            joinTimestamps[i] = joinTimestamp[teamAddresses[i]];
        }
        sortAddressesByTimestamp(result, joinTimestamps);
        uint arraylength;
        if (result.length > 10) {
            arraylength = 10;
        } else {
            arraylength = result.length;
        }
        address[] memory addressesToReturn = new address[](arraylength);

        for (uint i = 0; i < arraylength; i++) {
            uint length = result.length - 1;
            addressesToReturn[i] = result[length - i];
        }
        return addressesToReturn;
    }


    function sortAddressesByTimestamp(address[] memory addressesArr, uint256[] memory timestampsArr) internal pure {
        uint256 n = addressesArr.length;
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (timestampsArr[j] > timestampsArr[j + 1]) {
                    // Swap addresses
                    address tempAddress = addressesArr[j];
                    addressesArr[j] = addressesArr[j + 1];
                    addressesArr[j + 1] = tempAddress;
                    // Swap timestamps
                    uint256 tempTimestamp = timestampsArr[j];
                    timestampsArr[j] = timestampsArr[j + 1];
                    timestampsArr[j + 1] = tempTimestamp;
                }
            }
        }
    }

    /////recentjoined


// function createlegarray(address _ref, address[] memory to) public onlyOwner {


//     address[19][2] memory legArray = [
//         [
//             [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4],
//             [0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB]
//         ],
//         [
//             [0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2],
//             [0xdD870fA1b7C4700F2BD7f44238821C26f7392148, 0x583031D1113aD414F02576BD6afaBfb302140225, 0x145497854C104D8907b0FA2f267BC03CdaC15A73]
//         ],

//         [
//             [0xdD870fA1b7C4700F2BD7f44238821C26f7392148],
//             [0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C]
//         ],
//         [
//             [0x145497854C104D8907b0FA2f267BC03CdaC15A73],
//             [0x6d1e0872da0ab42819333fbe1da31cc3eb76ea0b]
//         ],
//         [
//             [0x583031D1113aD414F02576BD6afaBfb302140225],
//             [0xf5f5e8b847e3c307d3a8a013c5045e68e7a15e58]
//         ],

//         [
//             [0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C],
//             [0x617F2E2fD72FD9D5503197092aC168c91465E7f2]
//         ],

//         [
//             [0x617F2E2fD72FD9D5503197092aC168c91465E7f2],
//             [0x2c8824C1a017C1a9D29Fd0A922B12DBb62743094, 0xe9B69a4B047B1c05040D02CDACc968099AD517D1, 0x03458d0153C790484C8d4b6d2623653f8C405c24, 0x2C04587Bb6dB9aa84707b628CDA53877116274Ce]
//         ],

//         [
//             [0x2c8824C1a017C1a9D29Fd0A922B12DBb62743094],
//             [0xe384caee1f7aa6b5cbfbcfc559613c308d99b70a, 0xFc8A18D9717907EEF9947C289100994863562323, 0x2cAc632D423A869E2F4449504510c2b4CF1712b6]
//         ],
//         [
//             [0xe9B69a4B047B1c05040D02CDACc968099AD517D1],
//             [0x69c904121f89df7031eab2ab5e7b5e4aa596ee48, 0x365466f8e794816dd74a974619f899d002a4b9e7, 0xb07c605304cfc759df44d2e427967be5438627e1]
//         ],
//         [
//             [0x03458d0153C790484C8d4b6d2623653f8C405c24],
//             [0xa968608f1c2c0bb27ad5e13523c5d43240eb4336, 0xd047ce3af761222a3b3ad2bf64f64ff42362878d, 0x64b630d2725ae9bf514d0b1e970f417d526a0447]
//         ],


//         [
//             [0xFc8A18D9717907EEF9947C289100994863562323],
//             [0xf80BaE4f3c2B89420214EF82F9fE65cF20ddC0D8]
//         ],
//         [
//             [0xe384caee1f7aa6b5cbfbcfc559613c308d99b70a],
//             [0xF13aDA1352FB9a95e26fD6979Be451b07c759b3B]
//         ],
//         [
//             [0x2cAc632D423A869E2F4449504510c2b4CF1712b6],
//             [0x15b89515c5Fd0A390B63852A882B6c939E1b7d83]
//         ],


//         [
//             [0x365466f8e794816dd74a974619f899d002a4b9e7],
//             [0x8124144814f4db53df76e203898daf704e287cd7]
//         ],
//         [
//             [0x69c904121f89df7031eab2ab5e7b5e4aa596ee48],
//             [0xeA460b5e894061CDf6344605982C62f26Ad83f99]
//         ],
//         [
//             [0xb07c605304cfc759df44d2e427967be5438627e1],
//             [0xcf319c46fd0207b5ffae0e09412895520c44770d]
//         ],


//         [
//             [0xa968608f1c2c0bb27ad5e13523c5d43240eb4336],
//             [0xCF319C46fD0207B5FFaE0E09412895520C44770D]
//         ],
//         [
//             [0xd047ce3af761222a3b3ad2bf64f64ff42362878d],
//             [0x3Ad4Ac21F7d79F513fB8e6EfdabD0Bc7FBB88FBE]
//         ],
//         [
//             [0x64b630d2725ae9bf514d0b1e970f417d526a0447],
//             [0xf7fC72E44a385cad41272CDd4107B5BC9a3958bd]
//         ]
//     ];

//     for (uint i = 0; i < to.length; i++) {
//         referrals[_ref].push(to[i]);
//         joinTimestamp[to[i]] = block.timestamp; // Record the join timestamp
//     }
// }




}




/////////////////////////////////////////////////////////////////////////////////////



/*
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 - owner
0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
0x617F2E2fD72FD9D5503197092aC168c91465E7f2
0x17F6AD8Ef982297579C203069C1DbfFE4348c372
0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678
0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7
0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C
0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC

0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c
0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB
0x583031D1113aD414F02576BD6afaBfb302140225
0xdD870fA1b7C4700F2BD7f44238821C26f7392148

new account

extra addresses:

0x145497854C104D8907b0FA2f267BC03CdaC15A73
0x3d3Fea0c7951b93ED9985819BfA53c78Eb0E9079
0x855888e5a566900F5B35F7E7C599d06A1C8453C3
0x2c8824C1a017C1a9D29Fd0A922B12DBb62743094
0xe9B69a4B047B1c05040D02CDACc968099AD517D1
0x03458d0153C790484C8d4b6d2623653f8C405c24
0x2C04587Bb6dB9aa84707b628CDA53877116274Ce
0x745d27CE49B9255FB0cf178900B257758b7E2BC7
0x15A79F9b517Db1879a6c1e7cB37Db3ffC5F886e9
0x5b841492C4C97e2D98b35293fe8c019A101eE87a
0xDA70DA3aA6Ad11C108AE82cddb91331750D59EB9
0x70a67B53eD69C66bAae7B87c5c6C4D5a1a6E7B40
0x1bDee337f4876562c03bd7d52bB1cdaB134Bd6a1
0x59C772bBBdfcCCcd263aAaB144a84A2Ff7e2355f
0x2630aAF028EbA3CB6075A37d6aeaA4e141C96c7e
0x6d1e0872da0ab42819333fbe1da31cc3eb76ea0b
0xf5f5e8b847e3c307d3a8a013c5045e68e7a15e58
0xf59b3d83b0c007622e479facc92c928e59d5ca29
0x094f558ad2c0c3417235c320a5fb2ff635eb2ab5
0xd4f13bcd340238259de8210283968f806516b9b9

0xe384caee1f7aa6b5cbfbcfc559613c308d99b70a


0x17722695984a3f34820e51bD2d886465c6F5b81F
0x11A76a65e6f687C662B491f00A922a1e25E6e5d6
0x523f5B74A47aa4A679684C0c38C1520d70494A4D
0xE40cE2099DBd93413c4ef7C9FAc2141DD9Eea947
0x32D7DcA0E565677B52Bc9d316621FB45ae9FA7dE
0x23979B2BDb8c4cb6ab36f13f7B33428fdc832a15
0x2E90dC0c6e3215F4400E001B53F8bD2F7367BC8d
0x3F0a12A7eC0cf3309D7eF6f600e2533D104c004c
0xC3eda0903CA8a6C7Ee9Ccaa11C0932D820569480
0x42017a1f2d33C70C796eA4483A4d2E0E3ea9A2a5
0x344Ed07a4aB47214db2E9866324481890f307d03
0xa7ea1a57d2b59B0D0cb94A56787D2ce0b20d49c3
0x2e10c4102AD31Ca70eE363461A601Bf0cedA3d56
0xAef1e1e67338C41fE7F95132aF2ea78b0A22C234
0x1eDe34f26e164A3e7CdA35F138C9a4705eCE6b77


0x365466f8e794816dd74a974619f899d002a4b9e7
0xb07c605304cfc759df44d2e427967be5438627e1
0xeA460b5e894061CDf6344605982C62f26Ad83f99
0x8124144814f4db53df76e203898daf704e287cd7
0xcf319c46fd0207b5ffae0e09412895520c44770d
0xd047ce3af761222a3b3ad2bf64f64ff42362878d
0x64b630d2725ae9bf514d0b1e970f417d526a0447
0xCF319C46fD0207B5FFaE0E09412895520C44770D
0x3Ad4Ac21F7d79F513fB8e6EfdabD0Bc7FBB88FBE
0xf7fC72E44a385cad41272CDd4107B5BC9a3958bd
0x1da7c5183ce50e39b6f7e628b73ce6c6dbee83d7
0x076E79C4Ea686Daa9993a00e80e01A656abcF621
0x17f02353072003c331c4e6438cbd5e72d2cad481
0x6e6a6adabfed9b083876898bd29db90e2508db87

 uint[][] memory legArray= [[[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4],["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]],
[[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2],["0xdD870fA1b7C4700F2BD7f44238821C26f7392148","0x583031D1113aD414F02576BD6afaBfb302140225","0x145497854C104D8907b0FA2f267BC03CdaC15A73"]],

[[0xdD870fA1b7C4700F2BD7f44238821C26f7392148],["0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C"]],
[[0x145497854C104D8907b0FA2f267BC03CdaC15A73],["0x6d1e0872da0ab42819333fbe1da31cc3eb76ea0b"]],
[[0x583031D1113aD414F02576BD6afaBfb302140225],["0xf5f5e8b847e3c307d3a8a013c5045e68e7a15e58"]],

[[0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C],["0x617F2E2fD72FD9D5503197092aC168c91465E7f2"]],

[[0x617F2E2fD72FD9D5503197092aC168c91465E7f2],["0x2c8824C1a017C1a9D29Fd0A922B12DBb62743094","0xe9B69a4B047B1c05040D02CDACc968099AD517D1","0x03458d0153C790484C8d4b6d2623653f8C405c24","0x2C04587Bb6dB9aa84707b628CDA53877116274Ce"]],

[[0x2c8824C1a017C1a9D29Fd0A922B12DBb62743094],["0xe384caee1f7aa6b5cbfbcfc559613c308d99b70a","0xFc8A18D9717907EEF9947C289100994863562323","0x2cAc632D423A869E2F4449504510c2b4CF1712b6"]],
[[0xe9B69a4B047B1c05040D02CDACc968099AD517D1],["0x69c904121f89df7031eab2ab5e7b5e4aa596ee48","0x365466f8e794816dd74a974619f899d002a4b9e7","0xb07c605304cfc759df44d2e427967be5438627e1"]],
[[0x03458d0153C790484C8d4b6d2623653f8C405c24],["0xa968608f1c2c0bb27ad5e13523c5d43240eb4336","0xd047ce3af761222a3b3ad2bf64f64ff42362878d","0x64b630d2725ae9bf514d0b1e970f417d526a0447"]],


[[0xFc8A18D9717907EEF9947C289100994863562323],["0xf80BaE4f3c2B89420214EF82F9fE65cF20ddC0D8"]],
[[0xe384caee1f7aa6b5cbfbcfc559613c308d99b70a],["0xF13aDA1352FB9a95e26fD6979Be451b07c759b3B"]],
[[0x2cAc632D423A869E2F4449504510c2b4CF1712b6],["0x15b89515c5Fd0A390B63852A882B6c939E1b7d83"]],


[[0x365466f8e794816dd74a974619f899d002a4b9e7],["0x8124144814f4db53df76e203898daf704e287cd7"]],
[[0x69c904121f89df7031eab2ab5e7b5e4aa596ee48],["0xeA460b5e894061CDf6344605982C62f26Ad83f99"]],
[[0xb07c605304cfc759df44d2e427967be5438627e1],["0xcf319c46fd0207b5ffae0e09412895520c44770d"]],


[[0xa968608f1c2c0bb27ad5e13523c5d43240eb4336],["0xCF319C46fD0207B5FFaE0E09412895520C44770D"]],
[[0xd047ce3af761222a3b3ad2bf64f64ff42362878d],["0x3Ad4Ac21F7d79F513fB8e6EfdabD0Bc7FBB88FBE"]],
[[0x64b630d2725ae9bf514d0b1e970f417d526a0447],["0xf7fC72E44a385cad41272CDd4107B5BC9a3958bd"]]];

                                  5B3
                                /  |  \
                              /    |    \
                           Ab8    4B2      787
                           /\     /  \      / \
                          /  \   |    |    /   \
                       dD8  583  4B0 147  CA3   0A0
                        |         |               |
                        |         |               |
                        1aE       03C            5c6
                        |                         |
                        |                         |
                        617                       17F



/////////////////////////////////////////////////////////////////////////////////////

1x nft level4
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]
{leg no 1}

0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,["0xdD870fA1b7C4700F2BD7f44238821C26f7392148","0x583031D1113aD414F02576BD6afaBfb302140225","0x145497854C104D8907b0FA2f267BC03CdaC15A73"]

0xdD870fA1b7C4700F2BD7f44238821C26f7392148,["0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C"]
0x145497854C104D8907b0FA2f267BC03CdaC15A73,["0x6d1e0872da0ab42819333fbe1da31cc3eb76ea0b"]
0x583031D1113aD414F02576BD6afaBfb302140225,["0xf5f5e8b847e3c307d3a8a013c5045e68e7a15e58"]

0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C,["0x617F2E2fD72FD9D5503197092aC168c91465E7f2"]

      1x nft level3
0x617F2E2fD72FD9D5503197092aC168c91465E7f2,["0x2c8824C1a017C1a9D29Fd0A922B12DBb62743094","0xe9B69a4B047B1c05040D02CDACc968099AD517D1","0x03458d0153C790484C8d4b6d2623653f8C405c24","0x2C04587Bb6dB9aa84707b628CDA53877116274Ce"]

      3x nft level2                          
0x2c8824C1a017C1a9D29Fd0A922B12DBb62743094,["0xe384caee1f7aa6b5cbfbcfc559613c308d99b70a","0xFc8A18D9717907EEF9947C289100994863562323","0x2cAc632D423A869E2F4449504510c2b4CF1712b6"]
0xe9B69a4B047B1c05040D02CDACc968099AD517D1,["0x69c904121f89df7031eab2ab5e7b5e4aa596ee48","0x365466f8e794816dd74a974619f899d002a4b9e7","0xb07c605304cfc759df44d2e427967be5438627e1"]
0x03458d0153C790484C8d4b6d2623653f8C405c24,["0xa968608f1c2c0bb27ad5e13523c5d43240eb4336","0xd047ce3af761222a3b3ad2bf64f64ff42362878d","0x64b630d2725ae9bf514d0b1e970f417d526a0447"]

{2c8 reffer}    3x nft level1                                      3x investment 100 eth
0xFc8A18D9717907EEF9947C289100994863562323,["0xf80BaE4f3c2B89420214EF82F9fE65cF20ddC0D8"]
0xe384caee1f7aa6b5cbfbcfc559613c308d99b70a,["0xF13aDA1352FB9a95e26fD6979Be451b07c759b3B"]
0x2cAc632D423A869E2F4449504510c2b4CF1712b6,["0x15b89515c5Fd0A390B63852A882B6c939E1b7d83"]

{e9B reffer}     3x nft level1                                      3x investment 100 eth 
0x365466f8e794816dd74a974619f899d002a4b9e7,["0x8124144814f4db53df76e203898daf704e287cd7"]
0x69c904121f89df7031eab2ab5e7b5e4aa596ee48,["0xeA460b5e894061CDf6344605982C62f26Ad83f99"]
0xb07c605304cfc759df44d2e427967be5438627e1,["0xcf319c46fd0207b5ffae0e09412895520c44770d"]

{034 reffer}   3x nft level1                          3x investment 100 eth     
0xa968608f1c2c0bb27ad5e13523c5d43240eb4336,["0xCF319C46fD0207B5FFaE0E09412895520C44770D"]
0xd047ce3af761222a3b3ad2bf64f64ff42362878d,["0x3Ad4Ac21F7d79F513fB8e6EfdabD0Bc7FBB88FBE"]
0x64b630d2725ae9bf514d0b1e970f417d526a0447,["0xf7fC72E44a385cad41272CDd4107B5BC9a3958bd"]
=========================================
{leg no 2}

0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,["0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB","0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C","0x3d3Fea0c7951b93ED9985819BfA53c78Eb0E9079"]

0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB,["0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7"]
    1x nft level3
0x3d3Fea0c7951b93ED9985819BfA53c78Eb0E9079,["0x745d27CE49B9255FB0cf178900B257758b7E2BC7","0x15A79F9b517Db1879a6c1e7cB37Db3ffC5F886e9","0x5b841492C4C97e2D98b35293fe8c019A101eE87a","0xDA70DA3aA6Ad11C108AE82cddb91331750D59EB9"]
0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,["0xf59b3d83b0c007622e479facc92c928e59d5ca29"]

{3d3 reffer}    3x nft level2                           
0x745d27CE49B9255FB0cf178900B257758b7E2BC7,["0x35ba980b295d89db70574bc7716f4e6d1c988b73","0x7B4D320dB9c154236038A4211E90758E1916D386","0x9f16CAab0aB135b5c08F9b7Fd02e431632BD7413"]
0x15A79F9b517Db1879a6c1e7cB37Db3ffC5F886e9,["0xde4ca31420f8c05ab6a36f1ec2e61105101f5609","0x894D243a5dccaF2Bd57E646F269C6c70d8Bd0cBe","0x345783F9a5E39Ee9232d3857D2ab6D5107897ed3"]
0x5b841492C4C97e2D98b35293fe8c019A101eE87a,["0x62c9f4bce262e53f785fe247245a3b2890edb6ed","0x1dDa745C6A0D2b745b5f11acEc9935714Eabff71","0x2AE34AAaB68F9D6C47F9076c89033a59Bc62c5C5"]


{745 reffer}
0x7B4D320dB9c154236038A4211E90758E1916D386,["0x98d0f5AE580028EF70839887c765EdE94E9c5d91"]
0x35ba980b295d89db70574bc7716f4e6d1c988b73,["0xf26f2645e1250737795f56Cc06B1d1832d3fBAa8"]
0x9f16CAab0aB135b5c08F9b7Fd02e431632BD7413,["0xE1A23abdFd73e7A04bab7b32e4A2888cA4133444"]

{15A reffer}
0xde4ca31420f8c05ab6a36f1ec2e61105101f5609,["0x73C0F874906587b37ABA01925e1E0e60Bb1a2ac9"]
0x894D243a5dccaF2Bd57E646F269C6c70d8Bd0cBe,["0xe6F2Fa24e44fdeE9EE3F5005099DC4d66696e240"]
0x345783F9a5E39Ee9232d3857D2ab6D5107897ed3,["0x22Dbb91636Fe8Be91e086c9A68c5d58C179304F0"]

{5b8 reffer} 3x nft level1                          3x investment 100 eth  
0x1dDa745C6A0D2b745b5f11acEc9935714Eabff71,["0x62A0558AE229533076060fA58169F53Ce73D1D19"]
0x62c9f4bce262e53f785fe247245a3b2890edb6ed,["0x5b9c0F36C8D6CC54260aBF3CB8120fC14Ec91059"]
0x2AE34AAaB68F9D6C47F9076c89033a59Bc62c5C5,["0x52899944048371ae7F27448103961629959de406"]


=========================================
{leg no 3}

0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,["0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c","0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC","0x855888e5a566900F5B35F7E7C599d06A1C8453C3"]

0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c,["0x094f558ad2c0c3417235c320a5fb2ff635eb2ab5"]
0x855888e5a566900F5B35F7E7C599d06A1C8453C3,["0xd4f13bcd340238259de8210283968f806516b9b9"]
0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC,["0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678"]

{0A0 reffer}
0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678,["0x17F6AD8Ef982297579C203069C1DbfFE4348c372"]

{5c6 reffer}    1x nft level3
0x17F6AD8Ef982297579C203069C1DbfFE4348c372,["0x70a67B53eD69C66bAae7B87c5c6C4D5a1a6E7B40","0x1bDee337f4876562c03bd7d52bB1cdaB134Bd6a1","0x59C772bBBdfcCCcd263aAaB144a84A2Ff7e2355f","0x2630aAF028EbA3CB6075A37d6aeaA4e141C96c7e"]

{17F reffer}   3x nft level2                           
0x70a67B53eD69C66bAae7B87c5c6C4D5a1a6E7B40,["0x6cfd5d9397fed63376cfa89cc5f77af492254b28","0x17722695984a3f34820e51bD2d886465c6F5b81F","0x11A76a65e6f687C662B491f00A922a1e25E6e5d6"]
0x1bDee337f4876562c03bd7d52bB1cdaB134Bd6a1,["0x81550c33fcafd7a1801def3b8ac80fbedccb18c7","0x523f5B74A47aa4A679684C0c38C1520d70494A4D","0xE40cE2099DBd93413c4ef7C9FAc2141DD9Eea947"]
0x59C772bBBdfcCCcd263aAaB144a84A2Ff7e2355f,["0x17396028b50a1ce3c29fe28421d240d1b63c67ed","0x32D7DcA0E565677B52Bc9d316621FB45ae9FA7dE","0x23979B2BDb8c4cb6ab36f13f7B33428fdc832a15"]

{70a reffer}
0x6cfd5d9397fed63376cfa89cc5f77af492254b28,["0x2E90dC0c6e3215F4400E001B53F8bD2F7367BC8d"]
0x17722695984a3f34820e51bD2d886465c6F5b81F,["0x3F0a12A7eC0cf3309D7eF6f600e2533D104c004c"]
0x11A76a65e6f687C662B491f00A922a1e25E6e5d6,["0xC3eda0903CA8a6C7Ee9Ccaa11C0932D820569480"]

{1bD reffer}
0x523f5B74A47aa4A679684C0c38C1520d70494A4D,["0x42017a1f2d33C70C796eA4483A4d2E0E3ea9A2a5"]
0x81550c33fcafd7a1801def3b8ac80fbedccb18c7,["0x344Ed07a4aB47214db2E9866324481890f307d03"]
0xE40cE2099DBd93413c4ef7C9FAc2141DD9Eea947,["0xa7ea1a57d2b59B0D0cb94A56787D2ce0b20d49c3"]

{59c reffer}   3x nft level1                          3x investment 100 eth     
0x17396028b50a1ce3c29fe28421d240d1b63c67ed,["0x2e10c4102AD31Ca70eE363461A601Bf0cedA3d56"]
0x32D7DcA0E565677B52Bc9d316621FB45ae9FA7dE,["0xAef1e1e67338C41fE7F95132aF2ea78b0A22C234"]
0x23979B2BDb8c4cb6ab36f13f7B33428fdc832a15,["0x1eDe34f26e164A3e7CdA35F138C9a4705eCE6b77"]

===========================================================

















0x1da7c5183ce50e39b6f7e628b73ce6c6dbee83d7
0x076E79C4Ea686Daa9993a00e80e01A656abcF621
0x17f02353072003c331c4e6438cbd5e72d2cad481
0x6e6a6adabfed9b083876898bd29db90e2508db87


0x70a67B53eD69C66bAae7B87c5c6C4D5a1a6E7B40,["0x6cfd5d9397fed63376cfa89cc5f77af492254b28"]





*/
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/*
95000000000000000000000
31000000000000000000000

100000000000000000000 false ether;
500000000000000000000 false ether;
1000000000000000000000 false ether;
2500000000000000000000 false ether;
5000000000000000000000 false ether;
10000000000000000000000 false ether;
25000000000000000000000 false ether;
50000000000000000000000 false ether;


                5B3
              /  |  \
           Ab8  4B2   787
         /  |   |  |   |   \
      dD8 583  4B0 147 CA3  0A0
       |         |           |
      1aE       03C         5c6
*/




/*

add check ranking function
teamsales volume is not increasing
mapping changed for userinvestment

*/