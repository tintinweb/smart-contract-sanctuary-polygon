// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;


interface IERC20 {
   
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

}

contract LOTTO {
    address payable public ownerAddress;

    //lotto contract
    IERC20 busd;
    uint256 public lastId = 1;
    uint256 public nftId = 1;

    //Nft contract
    uint256 public globalAmount = 0;
    uint256 nftBuyAmount = 50 ether;
    uint256 secondNftBuyAmount = 200 ether;
    uint256 DevEarningsPer = 1000;
    NftMintInterface NftMint;
    uint8 constant BonusLinesCount = 5;
    uint256[BonusLinesCount] public referralBonus = [2000, 1000, 600, 200, 200];
    uint16 constant percentDivider = 10000;
    uint256 public accumulatRoundID = 1;

    uint256[6] public accumulatedAmount = [
        5 ether,
        2 ether,
        1 ether,
        1 ether,
        1 ether
    ];

    address[4] public adminsWalletAddress = [
        0xeC1cd23986763E2d03a09fb36F2d6A38447D8249,
        0xc8A00dcECF0cfE1060Cb684D56d470ead73F9F6F,
        0x93D1a91CBa4eB8d29d079509a3CD7Ec2109E5E42,
        0x703632A0b52244fAbca04aaE138fA8EcaF72dCBC
    ];

    struct playerStruct {
        uint256 playerId;
        address referral;
        uint256 totalReferralCount;
        uint256 vipReferrals;
        uint256 totalReward;
        bool isBuyFirstNft;
        bool isBuySecondNft;
        uint256 nft200Earning;
        uint256 levelEarnings;
        uint256 earnings;

        mapping(uint256 => uint256) referralEarningsL;
        mapping(uint256 => uint256) referrals;
    }

    struct bet {
        uint256 gameId;
        uint256 nftId;
        bool isClaim;
        uint256[6] betsNumber;
        uint256 totalMatchNumber;
    }

    struct PlayerDailyRounds {
        uint256 referrers; // total referrals user has in a particular round
        uint256 totalReferralInsecondNft;
    }

    struct RequestStatus {
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    struct BetResult {
        uint256 gameId;
        uint8 status;
    }

    mapping(address => playerStruct) public player;
    mapping(uint256 => mapping(address => bet)) public bets;
    mapping(address => uint256) public getBetIdByWalletAddress;
    mapping(uint256 => BetResult) public betResult;
    mapping(uint256 => mapping(uint256 => bool)) public isPlayed;
    mapping(uint256 => uint256) public requestIdWithGameId;
    address public LottoGameAddress;
    uint256 public gameSpan = 300;

    mapping(uint256 => mapping(uint256 => address)) public round;
    mapping(address => mapping(uint256 => PlayerDailyRounds)) public plyrRnds_;

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    event PlayerDataEvent(
        uint256 playerId,
        address userAddress,
        address referral,
        uint256 time
    );
    
    event EarningEvent(
        uint256 referralAmount,
        address walletAddress,
        address referral,
        uint8 status,
        uint256 time
    );

    event ReferralDetails(
        address user,
        address referrer,
        uint256 roundId
    );

    constructor(address payable _ownerAddress) {
        busd = IERC20(0x1FAdc992EA93CcCEbE3F965e72DF9c7d0F4035c9);
        NftMint = NftMintInterface(0x7f5B60A048B4cb19a7BC22f0D0659D9B65D31476);
        ownerAddress = _ownerAddress;
        player[msg.sender].playerId = lastId;

        emit PlayerDataEvent(lastId, msg.sender, address(0), block.timestamp);
        lastId++;
    }

    function setLottoGameAddress(address _gameAddress) external
    {
        require(msg.sender == ownerAddress, "Only owner can change amount");
        LottoGameAddress = _gameAddress;     
    }

    function buyFirstNft(address _referral) public payable {
        IERC20(busd).transferFrom(msg.sender, address(this), nftBuyAmount);

        if (_referral != ownerAddress) {
            require(player[_referral].isBuyFirstNft, "Invalid referral");
            _setUpUpline(msg.sender, _referral);
        }

         playerStruct storage _playerStruct = player[msg.sender];
        bool isNew = false;
        if (player[msg.sender].playerId == 0) {
            uint256 _lastId = lastId;

            _playerStruct.playerId = _lastId;
            _playerStruct.referral = _referral;
            _playerStruct.isBuyFirstNft = true;

            player[_referral].totalReferralCount++;
            if(player[_referral].totalReferralCount==10)
            {
                player[_referral].earnings += player[_referral].levelEarnings;
                player[_referral].levelEarnings = 0;
            }
            lastId++;
            emit PlayerDataEvent(
                _lastId,
                msg.sender,
                _referral,
                block.timestamp
            );
            isNew = true;
        }

        if (player[_referral].isBuySecondNft == true ) {
            plyrRnds_[_referral][accumulatRoundID].referrers++;
            emit ReferralDetails(msg.sender,_referral,accumulatRoundID);
            _highestReferrer(_referral);
        }

        globalAmount += 1.25 ether;
        sendAccumulatedAmount();

        //referral distribution
        _refPayout(msg.sender, nftBuyAmount,isNew);
       
        uint256 DevEarnings = (nftBuyAmount * DevEarningsPer) / percentDivider;
        IERC20(busd).transfer(ownerAddress, DevEarnings);

        IERC20(busd).transfer(LottoGameAddress, 23.75 ether);

        player[msg.sender].isBuyFirstNft = true;
        NftMint.mintReward(msg.sender, nftBuyAmount);

        
    }

    function buySecondNft() public payable {
        IERC20(busd).transferFrom(
            msg.sender,
            address(this),
            secondNftBuyAmount
        );
        require(
            player[msg.sender].isBuyFirstNft,
            "You need to buy 50 USDT nft first"
        );
        require(
            !player[msg.sender].isBuySecondNft,
            "Allready bought this package"
        );
        address _referral = player[msg.sender].referral;
        if (player[_referral].isBuySecondNft == true ) {
            player[_referral].vipReferrals++;
            if (player[_referral].vipReferrals % 5 <= 4) {
                IERC20(busd).transfer(_referral, secondNftBuyAmount);
                player[_referral].earnings += secondNftBuyAmount;
                player[_referral].nft200Earning += secondNftBuyAmount;
                emit EarningEvent(secondNftBuyAmount, msg.sender, _referral,0, block.timestamp);
            }
            else {
            for (uint256 i = 0; i <= adminsWalletAddress.length; i++) {
                IERC20(busd).transfer(adminsWalletAddress[i], 50 * 1e18);
            }
        }
        }
        else{
            IERC20(busd).transfer(ownerAddress, secondNftBuyAmount);
        }

        NftMint.mintReward(msg.sender, secondNftBuyAmount);

        player[msg.sender].isBuySecondNft = true;
    }

    function _highestReferrer(address _referrer) private {
        address upline = _referrer;

        if (upline == address(0)) return;

        for (uint8 i = 0; i < 5; i++) {
            if (round[accumulatRoundID][i] == upline) break;

            if (round[accumulatRoundID][i] == address(0)) {
                round[accumulatRoundID][i] = upline;
                break;
            }

            if (
                plyrRnds_[_referrer][accumulatRoundID].referrers >
                plyrRnds_[round[accumulatRoundID][i]][accumulatRoundID]
                    .referrers
            ) {
                for (uint256 j = i + 1; j < 5; j++) {
                    if (round[accumulatRoundID][j] == upline) {
                        for (uint256 k = j; k <= 5; k++) {
                            round[accumulatRoundID][k] = round[
                                accumulatRoundID
                            ][k + 1];
                        }
                        break;
                    }
                }

                for (uint8 l = uint8(5 - 1); l > i; l--) {
                    round[accumulatRoundID][l] = round[accumulatRoundID][l - 1];
                }

                round[accumulatRoundID][i] = upline;

                break;
            }
        }
    }

    function _setUpUpline(address _addr, address _upline) private {
        require(player[_upline].playerId > 0, "Invalid referral");

        if (player[_addr].referral == address(0) && _upline != _addr) {
            player[_addr].referral = _upline;
            player[_addr].totalReferralCount++;
        }
    }

    function _refPayout(address _addr, uint256 _amount,bool isNew) private {
        address up = player[_addr].referral;

        for (uint256 i = 0; i < BonusLinesCount; i++) {
            if (up == address(0)) {
                up = ownerAddress;
            }

            uint256 amount = (_amount * referralBonus[i]) / percentDivider;
            if(i==0 || player[up].totalReferralCount>=10){
                player[up].earnings += amount;
            }
            if(player[up].totalReferralCount<10)
            {
                player[up].levelEarnings += amount;
            }
            player[up].referralEarningsL[i] = amount;
            if(isNew)
            {
                player[up].referrals[i]++;
            }
            up = player[up].referral;

            emit EarningEvent(amount, _addr, up,0, block.timestamp);
        }
    }

    function sendAccumulatedAmount() internal {
        if (globalAmount >= 10 * 1e18) {
            for (uint256 i = 0; i < 5; i++) {
                if (round[accumulatRoundID][i] != address(0)) {
                    player[round[accumulatRoundID][i]].earnings += accumulatedAmount[i];
                    player[round[accumulatRoundID][i]].nft200Earning += accumulatedAmount[i];
                    emit EarningEvent(accumulatedAmount[i], round[accumulatRoundID][i], address(0),1, block.timestamp);
                }
            }
            accumulatRoundID++;
            globalAmount = 0;
        }
    }

    function withdraw(uint256 activeId) external 
    {
        require(NftMint.ownerOf(activeId)==msg.sender,"You are not owner of active NFT");
        require((NftMint.getNftMintedDate(activeId)+365 minutes)>=block.timestamp,"Not active NFT");
        playerStruct storage _player = player[msg.sender];
        busd.transfer(msg.sender, _player.earnings);
        _player.totalReward += _player.earnings;
        _player.earnings = 0;
    }

    function setOwnerAddress(address payable _address) public {
        ownerAddress = _address;
    }

    function setNftAmount(uint256 amount) external {
        require(msg.sender == ownerAddress, "Only owner can change amount");
        nftBuyAmount = amount;
    }

    function setAdminsWalletAddress(address[4] memory walletAddress) public {
        require(msg.sender == ownerAddress, "Only owner can set authaddress");
        adminsWalletAddress = walletAddress;
    }

    function getHighestReferrer(uint256 roundId)
        external
        view
        returns (address[] memory _players, uint256[] memory counts)
    {
        _players = new address[](5);
        counts = new uint256[](5);

        for (uint8 i = 0; i < 5; i++) {
            _players[i] = round[roundId][i];
            counts[i] = plyrRnds_[_players[i]][roundId].referrers;
        }
        return (_players, counts);
    }

    function referralEarningInfo(address _addr)
        external
        view
        returns (
            uint256[5] memory referralEarningsL,
            uint256[5] memory referrals,
            uint256 nft200Earning,
            uint256 _totalReward,
            uint256 _vipReferrals,
            uint256 _levelEarnings,
            uint256 _earnings
        )
    {
        playerStruct storage _player = player[_addr];
        for (uint8 i = 0; i < 5; i++) {
            referralEarningsL[i] = _player.referralEarningsL[i];
            referrals[i] = _player.referrals[i];
        }

        return (referralEarningsL,referrals, _player.nft200Earning, _player.totalReward,_player.vipReferrals,_player.levelEarnings,_player.earnings);
    }

    function getUpline(address _addr) external view returns(address)
    {
        return player[_addr].referral;
    }
}

// contract interface
interface NftMintInterface {
    // function definition of the method we want to interact with
    function mintReward(address to, uint256 nftPrice) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function getNftMintedDate(uint256 nftId) external view returns (uint256);

    function getNftNftPrice(uint256 nftId) external view returns (uint256);
}