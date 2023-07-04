// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Strings.sol";

interface IPancakeRouter {

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external returns(uint256[] memory amounts);

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
    address public vestingContract = 0x3d6B04fDe8B0062247b8a564Ba48EBbD44Fc4E66;
    address[] usersMinted;

    uint256[8] costs = [100 ether, 500 ether, 1000 ether, 2500 ether, 5000 ether, 10000 ether, 25000 ether, 50000 ether];
    uint256[8] public NFT_Quantities = [10, 10, 10, 10, 10, 10, 10, 10];
    uint256[8] testcost = [100 ether, 200 ether, 300 ether, 400 ether, 500 ether, 600 ether, 700 ether, 800 ether];
    uint256[] public evcBurnKeys;
    uint256[] levelsMinted;

    string public baseExtension = ".json";
    string public baseURI = "ipfs://QmZLfZHMA5bXDPWRAeMvBAGokxgm1rF2DbgyrFrTfeoAv4/";

    bool public paused = false;
    bool public delegate = false;

    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public referralCount;
    mapping(address => address) myReferrer;
    mapping(address => address[]) referrals;
    mapping(address => bool)[8] public hasTokens;
    mapping(address => mapping(uint256 => uint256)) public mintUserDetails;
    mapping(address => uint256) public userInvestment;
    mapping(address => uint256) public joinTimestamp;
    mapping(address => uint256) public individualunilevelEarning;
    mapping(address => uint256) public individualRbEarning;
    mapping(address => uint256[]) public individualOwnedNFT;
    mapping(address => uint256) public individualEVCswapVesting;
    mapping(uint256 => BurnData) public evcBurnDetails;
    mapping(address => ReferralBonus) public vestingTransfers;

    struct AddressRank {
        address referrer;
        uint256 rank;
        uint256 percentage;
    }

    struct BurnData {
        uint256 cumulativeBurnAmount;
        uint256 timestamp;
    }

    struct LevelMint {
        uint256 level;
        uint256 timestamp;
    }

    struct ReferralBonus {
        address referrer;
        uint256 evcTransferAmount;
        address vestingContract;
    }

    Counters.Counter[8] public NFT_Counters;

    event directReferralRewardTransferred(address user, address directReferrer, uint256 rewardAmount);
    event indirectReferralRewardTransferred(address user, address indirectReferrer, uint256 rewardAmount);
    event test(uint256 evc);
    event amountA(uint256 _amountA);
    event amountB(uint256 _amountB);
    event Burn(address indexed recipient, uint256 amount);

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
    function mintNFT(uint256 _level, uint256 _mintPrice, bool _delegate, address _referrer) public {
        uint256 level = _level - 1;
        uint256 mintPrice = _mintPrice;
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
            IERC20(_token).safeTransferFrom(msg.sender, address(this), mintPrice);
            if (_delegate) {
                uint256 sharePrice = requiredPrice * 10 / 100;
                uint256 newMintPrice = requiredPrice + sharePrice;
                require(mintPrice >= newMintPrice, "Insufficient payment amount; if delegate is true, add 10% more.");
                uint256 shareToDelegate = mintPrice - requiredPrice;
                IERC20(_token).transfer(delegateAddress, shareToDelegate); //delegate removed out of if block
                if (indirectReferrer != address(0)) {
                    IERC20(_token).transfer(indirectReferrer, indirectReferralReward);
                    individualunilevelEarning[indirectReferrer] += indirectReferralReward; // unilevel
                    IERC20(_token).transfer(directReferrer, directReferralReward);
                    individualunilevelEarning[directReferrer] += directReferralReward; // unilevel
                    emit indirectReferralRewardTransferred(msg.sender, indirectReferrer, indirectReferralReward);
                } else if (directReferrer != address(0)) {
                    IERC20(_token).transfer(directReferrer, directReferralReward);
                    individualunilevelEarning[directReferrer] += directReferralReward; // unilevel
                    emit directReferralRewardTransferred(msg.sender, directReferrer, directReferralReward);
                }
            } else {
                require(mintPrice >= requiredPrice, "Insufficient payment amount");
                if (indirectReferrer != address(0)) {
                    IERC20(_token).transfer(indirectReferrer, indirectReferralReward);
                    individualunilevelEarning[indirectReferrer] += indirectReferralReward; // unilevel
                    IERC20(_token).transfer(directReferrer, directReferralReward);
                    individualunilevelEarning[directReferrer] += directReferralReward; // unilevel
                    emit indirectReferralRewardTransferred(msg.sender, indirectReferrer, indirectReferralReward);
                } else if (directReferrer != address(0)) {
                    IERC20(_token).transfer(directReferrer, directReferralReward);
                    individualunilevelEarning[directReferrer] += directReferralReward; // unilevel
                    emit directReferralRewardTransferred(msg.sender, directReferrer, directReferralReward);
                }
            }
        }
        NFT_Counters[level].increment();
        uint256 tokenId = NFT_Counters[level].current();
        userInvestment[msg.sender] += requiredPrice;
        _safeMint(msg.sender, tokenId);
        individualOwnedNFT[msg.sender].push(tokenId);
        hasTokens[level][msg.sender] = true;
        usersMinted.push(msg.sender);
        levelsMinted.push(_level);
        mintUserDetails[msg.sender][_level] = block.timestamp;
    }

    function mintNFT1(uint256 _level, uint256 _mintPrice, bool _delegate, address _referrer, address[] memory rbmembers, uint256[] memory rbpercentages) public {
        mintNFT(_level, _mintPrice, _delegate, _referrer);
        uint256 requiredPrice = costs[_level - 1];
        busdAndEvcRB(rbmembers, rbpercentages, requiredPrice);
        buyandBurnPerc(15, requiredPrice);
    }

    //View
    function getMintedLevelsByTime(address user, uint256 timeFrom, uint256 timeTo) public view returns(LevelMint[] memory) {
        require(timeFrom <= timeTo, "Invalid time range");
        LevelMint[] memory levels = new LevelMint[](8);
        uint256 count = 0;
        for (uint256 i = 1; i <= 8; i++) {
            uint256 timeMinted = mintUserDetails[user][i];
            if (timeMinted >= timeFrom && timeMinted <= timeTo) {
                LevelMint memory mint = LevelMint(i, timeMinted);
                levels[count] = mint;
                count++;
            }
        }
        LevelMint[] memory result = new LevelMint[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = levels[i];
        }
        return result;
    }

    function getMyReferrer(address _user) public view returns(address) {
        return myReferrer[_user];
    }

    function getNFTCost(uint256 _level) public view returns(uint256) {
        uint256 level = _level - 1;
        return costs[level];
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

    function getTotalBurnByTime(uint256 timeFrom, uint256 timeTo) public view returns(uint256) {
        require(timeFrom <= timeTo, "Invalid time range");
        uint256 totalBurn = 0;
        for (uint256 i = 0; i < evcBurnKeys.length; i++) {
            uint256 key = evcBurnKeys[i];
            if (key >= timeFrom && key <= timeTo) {
                totalBurn += evcBurnDetails[key].cumulativeBurnAmount;
            }
        }
        return totalBurn;
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

    function getUsersByMintTime(uint256 timeFrom, uint256 timeTo) public view returns(address[] memory, uint256[] memory) {
        address[] memory users = usersMinted;
        uint256[] memory levels = levelsMinted;
        uint256 count = 0;
        address[] memory filteredUsers = new address[](users.length);
        uint256[] memory filteredLevels = new uint256[](levels.length);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 level = levels[i];
            if (mintUserDetails[user][level] >= timeFrom && mintUserDetails[user][level] <= timeTo) {
                filteredUsers[count] = user;
                filteredLevels[count] = level;
                count++;
            }
        }
        address[] memory finalUsers = new address[](count);
        uint256[] memory finalLevels = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalUsers[i] = filteredUsers[i];
            finalLevels[i] = filteredLevels[i];
        }
        return (finalUsers, finalLevels);
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
    function busdAndEvcRB(address[] memory _persons, uint256[] memory RBpercentages, uint256 _mintAmount) public {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        address[] memory referralBonusList = _persons;
        uint256[] memory referralBonuspercentagesList = RBpercentages;
        IERC20(token0).approve(pancakeRouterAdress, _mintAmount);
        uint256 deadline = block.timestamp + 5000; // Define and assign the deadline variable
        for (uint256 i = 0; i < referralBonusList.length; i++) {
            address referrer = referralBonusList[i];
            uint256 percentageTransfer = referralBonuspercentagesList[i];
            uint256 transferableAmount = (_mintAmount * percentageTransfer) / 100;
            uint256 evcTransferAmount = (transferableAmount * 25) / 100;
            uint256 busdTransferAmount = (transferableAmount * 75) / 100;
            uint256[] memory amountA_B = IPancakeRouter(pancakeRouterAdress).swapExactTokensForTokens(evcTransferAmount, 0, path, vestingContract, deadline);
            vestingTransfers[referrer] = ReferralBonus(referrer, evcTransferAmount, vestingContract);
            individualEVCswapVesting[referrer] += amountA_B[1];
            emit amountA(amountA_B[0]);
            emit amountB(amountA_B[1]);
            IERC20(_token).transfer(referrer, busdTransferAmount);
            individualRbEarning[referrer] += busdTransferAmount;
        }
    }

    function buyandBurnPerc(uint256 perc, uint256 _mintAmount) internal {
        uint256 evcTransferAmount = (perc * _mintAmount) / 100;
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        uint256 deadline = block.timestamp + 5000;
        address deadAddress = 0x000000000000000000000000000000000000dEaD;
        IERC20(token0).approve(pancakeRouterAdress, _mintAmount);
        IPancakeRouter(pancakeRouterAdress).swapExactTokensForTokens(evcTransferAmount, 0, path, deadAddress, deadline);
        BurnData memory burnData = BurnData(evcTransferAmount, block.timestamp);
        evcBurnDetails[block.timestamp] = burnData;
        evcBurnKeys.push(block.timestamp);
        emit Burn(deadAddress, evcTransferAmount);
    }

    function filterFunction(address _account) internal view returns(address[] memory) {
        address[] memory filterarray = getTeamAddresses(_account);
        address[] memory teamAddressesWithoutFirst = new address[](filterarray.length - 1);
        for (uint256 i = 0; i < filterarray.length - 1; i++) {
            teamAddressesWithoutFirst[i] = filterarray[i + 1];
        }
        return teamAddressesWithoutFirst;
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
    function buyandBurnPercAdmin(uint256 _perc, uint256 _mintAmount) public onlyOwner {
        buyandBurnPerc(_perc, _mintAmount);
    }

    function changeInvestment(address _user, uint256 _value) public onlyOwner {
        userInvestment[_user] = _value;
    }

    function createReferralArray(address _ref, address[] memory to) public onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            address user = to[i];
            referrals[_ref].push(user);
            myReferrer[user] = _ref;
            joinTimestamp[user] = block.timestamp; // Record the join timestamp
        }
    }

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

    function setIndividualevcswaped(address _user, uint amount) public onlyOwner {
        individualEVCswapVesting[_user] += amount;
    }

    function setNftLevel(address _useradd, uint256 _level) public onlyOwner {
        require(_level >= 1 && _level <= 8, "Invalid NFT level");
        uint8 nftIndex = uint8(_level - 1);
        hasTokens[nftIndex][_useradd] = true;
    }

    function setPancakeRouterAdress(address _newpancakeRouterAdress) public onlyOwner {
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

    function setVestingContract(address _vestingcontract) public onlyOwner {
        vestingContract = _vestingcontract;
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }

    function withdraw() public payable onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

}

// 1,100000000000000000000,false,0x0000000000000000000000000000000000000000,["0x6585C0ddD01B0bEA7a8fa89d43f75c7fA12A80a7","0xc613e3239F877B3575cbD1B7253e137C377B03B5","0x68b97b12b27151b719000e232Aa731CEedEc13b7","0x73562B32fE64c2274aD4733c80b7626A9204593F","0x260782EA7a58c236e70E58A4314b916D22BBF609","0xE046143B54294B7060Fb35157f56eF6442ABC02e"],["7","8","4","4","2","1"]