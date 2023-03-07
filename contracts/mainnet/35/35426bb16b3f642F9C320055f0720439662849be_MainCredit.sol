// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./EnumerableSet.sol";
import "./Counters.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./IChallenge.sol";
import "./IERC20.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract MainCredit is Initializable, IERC721Receiver, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    enum TypeToken { ERC20, ERC721, ERC1155, NATIVE_TOKEN }
    enum DividendStatus { DIVIDEND_PENDING, DIVIDEND_SUCCESS, DIVIDEND_FAIL }
    enum ChallengeState { PROCESSING, SUCCESS, FAILED, GAVE_UP,CLOSED }
    enum TypeRequireBalanceNft { REQUIRE_BALANCE_WALLET, REQUIRE_BALANCE_CONTRACT, REQUIRE_BALANCE_ALL }

    modifier onlyAdmin() {
        require(admins.contains(msg.sender), "NOT ADMIN.");
        _;
    }

    //This is RewardToken struct.
    struct RewardToken{
        address addressToken;
        uint256 unlockRate;
        uint256 rewardValue;
        uint256 indexToken;
        TypeToken typeToken;
        bool isMintNft;
    }

    //This is ChallengeInfo struct.
    struct ChallengeInfo{
        uint256 targetStepPerDay;
        uint256 challengeDuration;
        uint256 stepDataToSend;
        uint256 toleranceAmount;
        DividendStatus dividendStatus;
        uint256 amountBaseDeposit;
        uint256 amountTokenDeposit;
        uint256 timeLimitActiveGacha;
        TypeRequireBalanceNft typeRequireBalanceNft;
    }

    struct UserInfor{
        bool statusRandom;
        uint256 indexReward;
        uint256 indexToken;
        address tokenAddress;
        uint256 rewardValue;
        string nameReward;
    }

    event AddNewReward(address indexed _addressToken, uint256 _unlockRate, TypeToken _typeToken, address _gachaAddress);

    event DeleteReward(address indexed _caller, uint256 _indexOfTokenReward, address _gachaAddress);
   
    event SendDailyResultGacha(address indexed _caller, address _gachaAddress);

    event CloseChallenge(address indexed _caller, address _gachaAddress);

    EnumerableSet.AddressSet private admins;// This is a function to store the address of admin.
    mapping(uint256 => RewardToken) public rewardTokens; // This is a mapping to store the reward token.
    Counters.Counter private totalNumberReward; // This is a function to count the total number of reward.
    mapping(address => mapping(address => bool)) public isSendDailyResultWithGacha;
    uint256[] private listIdToken;
    mapping(address => UserInfor) public userInfor;
    ChallengeInfo public challengeInfo;
    EnumerableSet.AddressSet private requireBalanceNftAddress;
    mapping(address => bool) public typeNfts;
    bool public isDefaultGachaContract;
    string public gachaName;
    string public gachaSponsor;
    bool public iscloseGacha;
    address private returnedNFTWallet;
    mapping(address => mapping(uint256 => uint256)) public countTimeActiveGacha;

    function initialize(
        ChallengeInfo memory _challengeInfo,
        address[] memory _requireBalanceNftAddress, 
        bool[] memory _typeNfts,
        uint256 _rateOfLost,
        bool _isDefaultGachaContract,
        string memory _gachaName,
        string memory _gachaSponsor
    ) external initializer {
         __UUPSUpgradeable_init();
        require(_requireBalanceNftAddress.length == _typeNfts.length, "INVALID REQUIRE BALANCE NFT ADDRESS.");
        challengeInfo = _challengeInfo;
        for(uint256 i = 0; i < _requireBalanceNftAddress.length; i++) {
            requireBalanceNftAddress.add(_requireBalanceNftAddress[i]);
            typeNfts[_requireBalanceNftAddress[i]] = _typeNfts[i];
        }
        isDefaultGachaContract = _isDefaultGachaContract;
        gachaName = _gachaName;
        gachaSponsor = _gachaSponsor;
        admins.add(msg.sender);
        rewardTokens[0].unlockRate = _rateOfLost;
    }
    
    /**
    *@dev function to be able to accept native currency of the network.
    */
    receive() external payable 
    {

    }

    // This function is used to send daily result gacha.
    function randomRewards(address _challengeAddress) external returns(bool){
        require(
            !isSendDailyResultWithGacha[msg.sender][_challengeAddress], 
            "ALREADY SEND DAILY RESULT WITH GACHA CONTRACT."
        );

        require(
            _challengeAddress == msg.sender, 
            "ONLY CHALLENGE CONTRACT CAN CALL SEND DAILY RESULT WITH GACHA."
        );

        address challengerAddress = IChallenge(_challengeAddress).challenger();
        uint256 currentDate = block.timestamp.div(86400);
        require(
            countTimeActiveGacha[challengerAddress][currentDate] < challengeInfo.timeLimitActiveGacha,
            "THE NUMBER OF ACTIVE GACHA TIMES IN A DAY HAS EXCEEDED THE LIMIT."
        );
        countTimeActiveGacha[challengerAddress][currentDate] = countTimeActiveGacha[challengerAddress][currentDate].add(1);
        UserInfor memory newUserInfor;
        userInfor[challengerAddress] = newUserInfor;
        bool isWonThePrize = false;
        // This is a loop to check if the reward token is exist or not.
        uint256 randomIndexReward = checkAbilityReward();
        if(randomIndexReward != 0) {
            if(checkRewardConditions( _challengeAddress)) {
                uint256 indexTokenReward;
                RewardToken memory currentRewardToken = rewardTokens[randomIndexReward];
                address currentTokenAddress = currentRewardToken.addressToken;
                if(currentRewardToken.typeToken == TypeToken.ERC20) {
                    // This is a function to transfer the reward token to the challenger address.
                    TransferHelper.safeTransfer(
                        currentTokenAddress,
                        challengerAddress,
                        currentRewardToken.rewardValue
                    );
                } else {     
                    if(currentRewardToken.typeToken == TypeToken.ERC721) {
                        uint256 currentIndexNFT = IChallenge(currentTokenAddress).nextTokenIdToMint();
                        if(currentRewardToken.isMintNft) {
                            IChallenge(IChallenge(_challengeAddress).erc721Address(0)).safeMintNFT721Heper(
                                currentTokenAddress,
                                challengerAddress
                            );
                            indexTokenReward = currentIndexNFT;
                        } else {
                            for(uint256 j = 0; j < currentIndexNFT; j++) {
                                if(IChallenge(currentTokenAddress).ownerOf(j) == address(this)) {
                                    TransferHelper.safeTransferFrom(
                                        currentTokenAddress,
                                        address(this),
                                        challengerAddress,
                                        j
                                    );
                                    indexTokenReward = j;
                                    break;
                                }
                            }
                        }   
                    }  else {
                        if(currentRewardToken.typeToken == TypeToken.ERC1155) {
                            if(currentRewardToken.isMintNft) {
                                IChallenge(IChallenge(_challengeAddress).erc721Address(0)).safeMintNFT1155Heper(
                                    currentTokenAddress,
                                    challengerAddress,
                                    currentRewardToken.indexToken,
                                    currentRewardToken.rewardValue
                                );
                            } else {
                                TransferHelper.safeTransferNFT1155(
                                    currentTokenAddress,
                                    address(this),
                                    challengerAddress,
                                    currentRewardToken.indexToken,
                                    currentRewardToken.rewardValue,
                                    "ChallengeApp"
                                );
                            }

                            indexTokenReward = currentRewardToken.indexToken;
                        } else {
                            TransferHelper.saveTransferEth(
                                payable(challengerAddress),
                                currentRewardToken.rewardValue
                            );
                        }
                    }
                }

                isWonThePrize = true;

                string memory tokenName;
                if(currentRewardToken.typeToken == TypeToken.NATIVE_TOKEN) {
                    tokenName = "Native Token";
                } else {
                    tokenName = IChallenge(currentTokenAddress).name();
                }
                userInfor[challengerAddress] = UserInfor(
                    true,
                    randomIndexReward,
                    indexTokenReward,
                    currentTokenAddress,
                    currentRewardToken.rewardValue,
                    tokenName
                );
            } 
        }

        if(isWonThePrize && IChallenge(_challengeAddress).isFinished()){
            isSendDailyResultWithGacha[msg.sender][_challengeAddress] = true;
        }

        emit SendDailyResultGacha(msg.sender, address(this));

        return isWonThePrize;
    } 

    function closeGacha() external onlyAdmin {
        require(!iscloseGacha, "GACHA ALREADY CLOSE.");
        require(returnedNFTWallet != address(0), "RETURNED NFT WALLET NOT YET SET UP.");
        for(uint256 i = 0; i < listIdToken.length; i++) {
            RewardToken memory currentRewardToken = rewardTokens[listIdToken[i]];
            address tokenAddress = currentRewardToken.addressToken;
            if(!currentRewardToken.isMintNft) {
                if(currentRewardToken.typeToken != TypeToken.ERC1155) {
                    if(currentRewardToken.typeToken == TypeToken.NATIVE_TOKEN) {
                        TransferHelper.saveTransferEth(
                            payable(returnedNFTWallet),
                            address(this).balance
                        );
                    } else {
                        uint256 balanceToken = IERC20(tokenAddress).balanceOf(address(this));
                        if(balanceToken > 0) {
                            if(currentRewardToken.typeToken == TypeToken.ERC20) {
                                TransferHelper.safeTransfer(
                                    tokenAddress,
                                    returnedNFTWallet,
                                    balanceToken
                                );
                            }

                            if(currentRewardToken.typeToken == TypeToken.ERC721) {
                                uint256 currentIndexNFT = IChallenge(tokenAddress).nextTokenIdToMint();
                                for(uint256 j = 0; j < currentIndexNFT; j++) {
                                    if(IChallenge(tokenAddress).ownerOf(j) == address(this)) {
                                        TransferHelper.safeTransferFrom(
                                            tokenAddress,
                                            address(this),
                                            returnedNFTWallet,
                                            j
                                        );
                                    }
                                }
                            }
                        }
                    }
                } else {
                    uint256 balanceTokenERC1155 = IERC1155(tokenAddress).balanceOf(address(this), currentRewardToken.indexToken);
                    if(balanceTokenERC1155 > 0) {
                        TransferHelper.safeTransferNFT1155(
                            tokenAddress,
                            address(this),
                            returnedNFTWallet,
                            currentRewardToken.indexToken,
                            balanceTokenERC1155,
                            "ChallengeApp"
                        );   
                    }
                }
            }
        }

        iscloseGacha = true;

        emit CloseChallenge(msg.sender, address(this));
    }
    
    // check reward 
    function checkAbilityReward() private view returns(uint256){
        uint256 totalUnlockReward = rewardTokens[0].unlockRate;
        for(uint256 i = 0; i < listIdToken.length; i++) {
            totalUnlockReward = totalUnlockReward.add(rewardTokens[listIdToken[i]].unlockRate);
        }
        uint256 ramdomNumber = checkRamdomNumber(totalUnlockReward);

        if(ramdomNumber <= rewardTokens[0].unlockRate) {
            return 0;
        }

        uint256 totalUnlock = rewardTokens[0].unlockRate;
        uint256 idReward;
        for(uint256 i = 0; i < listIdToken.length; i++) {
            if(ramdomNumber <= rewardTokens[listIdToken[i]].unlockRate + totalUnlock) {
                idReward = listIdToken[i];
                break;
            }
            totalUnlock = totalUnlock.add(rewardTokens[listIdToken[i]].unlockRate);
        }
        return idReward;
    }   
    
    // This function is used to add new reward.
    function addNewReward(
        address _addressToken,
        uint256 _unlockRate,
        uint256 _rewardValue,
        uint256 _indexToken,
        TypeToken _typeToken,
        bool _isMintNft
    ) external onlyAdmin{
        /*
        This is a function to check if the address token is not zero, 
        unlock rate is less than total rate and reward value is greater than zero.
        */
        if(
            _addressToken == address(0) && _typeToken != TypeToken.NATIVE_TOKEN ||
            _addressToken != address(0) && _typeToken == TypeToken.NATIVE_TOKEN
        ) {
            revert("ZERO ADDRESS.");
        }
        
        require(_rewardValue > 0, "INVALID REWARD VALUE.");

        // This function is used to add or update reward.
        uint256 indexOfTokenReward = 0;
        for(uint256 i = 1; i <= totalNumberReward.current(); i++) {
            if(
                rewardTokens[i].addressToken == address(0) && 
                rewardTokens[i].typeToken != TypeToken.NATIVE_TOKEN
            ) {
                indexOfTokenReward = i;
                break;
            }
        }

        if(indexOfTokenReward == 0 ){
            totalNumberReward.increment();
            indexOfTokenReward = totalNumberReward.current();
        }
        
        addReward(indexOfTokenReward, _addressToken, _unlockRate, _rewardValue, _indexToken, _typeToken, _isMintNft);
        listIdToken.push(indexOfTokenReward);

        emit AddNewReward(_addressToken, _unlockRate, _typeToken, address(this));
    }

    function checkRewardConditions(address _challengeAddress) private view returns(bool){
        uint256 challengeDuration = IChallenge(_challengeAddress).duration();
        // check balance NFT, require Balance Nft Address
        if(checkRequireBalanceNft(_challengeAddress)) {
            ChallengeInfo memory currentChallengeInfo = challengeInfo;
            if(currentChallengeInfo.targetStepPerDay <= IChallenge(_challengeAddress).goal()){
                if(currentChallengeInfo.challengeDuration <= challengeDuration){
                    (, uint256[] memory challengeHiostoryData) = IChallenge(_challengeAddress).getChallengeHistory();
                    bool isCorrectStepDataToSend = false;
                    for(uint256 i = 0; i < challengeHiostoryData.length; i++) {
                        if(currentChallengeInfo.stepDataToSend <= challengeHiostoryData[i]) {
                            isCorrectStepDataToSend = true;
                            break;
                        }
                    }
                    if(isCorrectStepDataToSend) {
                        if(IChallenge(_challengeAddress).dayRequired() >= challengeDuration.sub(challengeDuration.div(currentChallengeInfo.toleranceAmount))) {
                            if(
                                currentChallengeInfo.amountBaseDeposit <= IChallenge(_challengeAddress).totalReward() && 
                                IChallenge(_challengeAddress).allowGiveUp(1) ||
                                currentChallengeInfo.amountTokenDeposit <= IChallenge(_challengeAddress).totalReward() &&
                                !IChallenge(_challengeAddress).allowGiveUp(1)
                            ) {
                                if(currentChallengeInfo.dividendStatus == DividendStatus.DIVIDEND_PENDING){
                                    return true;
                                }

                                uint256[] memory awardReceiversPercent = IChallenge(_challengeAddress).getAwardReceiversPercent();

                                if(currentChallengeInfo.dividendStatus == DividendStatus.DIVIDEND_SUCCESS) {
                                address donationAddress = IChallenge(IChallenge(_challengeAddress).erc721Address(0)).donationWalletAddress();
                                require(donationAddress != address(0), "DONATION ADDRESS SHOULD BE DEFINED.");
                                    if(awardReceiversPercent[0] == 98) {
                                        if(IChallenge(_challengeAddress).getAwardReceiversAtIndex(0, true) == donationAddress) {
                                            return true;
                                        }
                                    }
                                }
                                
                                if(currentChallengeInfo.dividendStatus == DividendStatus.DIVIDEND_FAIL) {
                                    for(uint256 i = 1; i < awardReceiversPercent.length; i++) {
                                        if(awardReceiversPercent[i] == 98) {
                                            if(admins.contains(IChallenge(_challengeAddress).getAwardReceiversAtIndex(0, false)))
                                            return true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return false;
    }

    // This function is used to delete reward.
    function deleteReward(uint256 _indexOfTokenReward) external onlyAdmin{
        // Used to delete the reward token.
        bool isExistIndexToken = false;
        for(uint256 i = 0; i < listIdToken.length; i++) {
            if(_indexOfTokenReward == listIdToken[i]) {
                isExistIndexToken = true;
                break;
            }
        }
        require(isExistIndexToken, "INDEX OF TOKEN REWARD NOT EXIST.");
        
        delete rewardTokens[_indexOfTokenReward];
        for(uint256 i = 0; i < listIdToken.length; i++) {
            if(listIdToken[i] == _indexOfTokenReward) {
                listIdToken[i] = listIdToken[listIdToken.length.sub(1)];
            }
        }
        listIdToken.pop();

        emit DeleteReward(msg.sender, _indexOfTokenReward, address(this));
    }

    // This function is used to add or update reward.
    function addReward(
        uint256 _indexOfTokenReward,
        address _addressToken,
        uint256 _unlockRate,
        uint256 _rewardValue,
        uint256 _indexToken,
        TypeToken _typeToken,
        bool _isMintNft
    ) private {
        rewardTokens[_indexOfTokenReward] = RewardToken(
            _addressToken,
            _unlockRate,
            _rewardValue,
            _indexToken,
            _typeToken,
            _isMintNft
        );
    }

    // This function is used to find index of token reward.
    function findIndexOfTokenReward(address _addressToken) public view returns(uint256 indexOfTokenReward) {
        // This is a loop to check if the reward token is exist or not.
        for(uint256 i = 1; i <= totalNumberReward.current(); i++) {
            if(rewardTokens[i].addressToken == _addressToken) {
                indexOfTokenReward = i;
                break;
            }
        }
    }

    // This function is used to get total number of reward.
    function getTotalNumberReward() public view returns(uint256) {
        return totalNumberReward.current();
    }

    // This function is used to add or remove admin.
    function updateAdmin(address _adminAddr, bool _flag) external onlyAdmin {
        require(_adminAddr != address(0), "INVALID ADDRESS.");
        // This is a function to add or remove admin.
        if (_flag) {
            admins.add(_adminAddr);
        } else {
            admins.remove(_adminAddr);
        }
    }

    function updateChallengeInfor(ChallengeInfo memory _challengeInfo) external onlyAdmin{
        challengeInfo = _challengeInfo;
    }

    function updateRateOfLost(uint256 _rateOdLost) external onlyAdmin{
        rewardTokens[0].unlockRate = _rateOdLost;
    }

    // This function is used to get all admins.
    function getAdmins() external view returns (address[] memory) {
        return admins.values();
    }

    function checkRamdomNumber(uint256 _ramdomWithLimitValue) private view returns(uint256){
        require(_ramdomWithLimitValue > 0, "THE REWARD IS OVER.");
        // This is a function to generate random number.
        uint256 firstRamdomValue = uint256(
            keccak256(abi.encodePacked(
                block.number, block.difficulty, msg.sender, block.timestamp)
            )
        ) % _ramdomWithLimitValue;
        return firstRamdomValue.add(1);
    }
    
    // Check existence for index reward
    function checkExistenceIndexRewards(uint256[] memory data) private pure returns(bool){
        if(data.length == 1) {
            return true;
        }
        
        for(uint256 i = 0; i < data.length; i++) {
            for(uint256 j = i + 1; j < data.length; j++) {
                if(data[j] == data[i]) {
                    return false;
                }

            }
        }

        return true;
    }

    function checkRequireBalanceNft(address _challengeAddress) public view returns(bool) {
        if(isDefaultGachaContract){
            return true;
        }
        
        address challangerAddress = IChallenge(_challengeAddress).challenger();
 
        if(challengeInfo.typeRequireBalanceNft == TypeRequireBalanceNft.REQUIRE_BALANCE_WALLET) {
            return checkBalanceNft(challangerAddress);
        }

        if(challengeInfo.typeRequireBalanceNft == TypeRequireBalanceNft.REQUIRE_BALANCE_CONTRACT) {
            return checkBalanceNft(_challengeAddress);
        }

        if(challengeInfo.typeRequireBalanceNft == TypeRequireBalanceNft.REQUIRE_BALANCE_ALL) {
            return checkBalanceNft(challangerAddress) && checkBalanceNft(_challengeAddress);
        }

        return false;
    }

    function checkBalanceNft(address _fromAddress) internal view returns(bool) {
        for(uint256 i = 0; i < requireBalanceNftAddress.values().length; i++) {
            if(typeNfts[requireBalanceNftAddress.values()[i]]) {
                if(IERC721(requireBalanceNftAddress.values()[i]).balanceOf(_fromAddress) > 0) {
                    return true;
                }
            } else {
                uint256 currentIndexToken = IERC1155(requireBalanceNftAddress.values()[i]).nextTokenIdToMint();
                for(uint256 j = 0; j < currentIndexToken; j++) {
                    if(IERC1155(requireBalanceNftAddress.values()[i]).balanceOf(_fromAddress, j) > 0) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    function updateStatusDefaultGachaContract(bool _isDefaultGachaContract) external onlyAdmin {
        require(isDefaultGachaContract == isDefaultGachaContract, "THIS STATUS HAS BEEN SETTING.");
        isDefaultGachaContract = _isDefaultGachaContract;
    }

    function updateReturnedNFTWallet(address _returnedNFTWallet) external {
        require(
            msg.sender == returnedNFTWallet || returnedNFTWallet == address(0), 
            "ONLY RETURNED NFT WALLET ADDRESS."
        );
        require(_returnedNFTWallet != address(0), "INVALID RETURNED NFT WALLET ADDRESS.");
        returnedNFTWallet = _returnedNFTWallet;
    }

    function updateRequireBalanceNftAddress(address _nftAddress, bool _flag, bool _isTypeErc721) external onlyAdmin {
        require(_nftAddress != address(0), "INVALID NFT ADDRESS");
        if (_flag) {
            requireBalanceNftAddress.add(_nftAddress);
        } else {
            requireBalanceNftAddress.remove(_nftAddress);
        }
        typeNfts[_nftAddress] = _isTypeErc721;
    }

    function getRequireBalanceNftAddress() external view returns(address[] memory) {
        return requireBalanceNftAddress.values();
    }

    function getListIdToken() external view returns(uint256[] memory) {
        return listIdToken;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyAdmin
        override
    {

    }

    /**
     * @dev onERC721Received.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    /**
     * @dev onERC1155Received.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}