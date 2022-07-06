// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/*    
🅣🅗🅔🅡🅐🅝🅒🅗_🅑🅤🅛🅛🅢_➋⓿➋➋
*/

import "ReentrancyGuard.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";
import "ERC721Enumerable.sol";
import "Ownable.sol";
import "Counters.sol";
import "SafeERC20.sol";
import "IERC20.sol";
import { IERC2981, IERC165 } from "IERC2981.sol";


error Minting_ExceedsTotalBulls();
error Minting_PublicSaleNotLive();
error Minting_IsZeroOrBiggerThanTen();
error Contract_CurrentlyPaused_CheckSocials();
error Pause_MustSetAllVariablesFirst();
error Pause_BaseURIMustBeSetFirst();
error Pause_MustBePaused();
error Rewarding_NotReady();
error Maintenance_UpdatingNotReady();
error Liquidation_NothingToDo();
error BadLogicInputParameter();
error Stockyard_IsNotSetYet();
error Partner_NotAllowed();
error Address_CantBeAddressZero();
error Blacklisted();
error Rewarding_NoBalanceToWithdraw();

contract TheRanchBullsMintReward is 
    VRFConsumerBaseV2,
    ERC721Enumerable,
    IERC2981,
    Ownable,
    ReentrancyGuard {

        
   
    using Strings for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    address public wbtcTokenContract;
    uint public wbtcTokenDecimals = 8;
    address public usdcTokenContract;
    uint public usdcTokenDecimals = 6;

    // coreTeam Addresses
    address public coreTeam_1;
    address public coreTeam_2;
    uint256 public coreTeam_1_percent = 8;
    uint256 public coreTeam_2_percent = 2;

    //gnosis-safe address 
    address public hostingSafe;
    address public btcMinersSafe;

    // Minting 
    uint256 public mintingCost = 350;  // USDC.e
    uint public constant maxSupply = 10000;

    bool public publicSaleLive = false;
    bool public paused = true;

    mapping(address => bool) public isBlacklisted;

    mapping(address => uint) public userMintCount;  // How many bulls did an address mint
    mapping(address => bool) public userInDailyRaffle;  // Is the person already in the daily raffle?

    mapping(address => address) public myPartner;   // partner mapping; msg.sender  ==> who referred them
    mapping(address => uint256) public myParnterNetworkTeam;   // partner mapping; msg.sender  ==> who referred them

    // Contract Balances
    uint256 public btcMinersSafeBalance;
    uint256 public hostingSafeBalance;     // reserve kept for hosting fees and will be used if people don't pay their maintenance fees on time
    uint256 public USDCRewardsBalance;    // amount held within contract for referrals and raffle balance 
    uint256 public dailyRaffleBalance;    // Strictly the Raffle amount of USDC to be award on the raffle 
    mapping (address => uint256) USDCRewardsForAddress; // amount of USDC user is allowed to via the referral and raffle reward system
    mapping (address => uint256) WBTCRewardsForAddress;     
  

    // NFT INFO 
    string private baseURI;
    string private baseExtension = ".json";
 
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private  vrfCoordinator;
    uint64 private subscriptionId;
    bytes32 private gasLane;
    uint32 private callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS_DAILY = 1;          // used for daily raffle
  
    // Raffle Variables
    address[] private dailyRafflePlayers;
 
    // Maintenance Fees Variables and Mappings
    // The amount calculated for hosting invoice / NFT count 
    uint256 public calculatedMonthlyMaintenanceFee;   


    // monththy storage that gets reset every month
    mapping(address => bool) monthlyMaintanenceFeeDue;
    mapping(address => uint) nftsHeldByAddressAtMonthlyPayout;
    address[] public addressesToPayMaintenanceFees; 
 
    // lifetimeStorage
    mapping(address =>bool) hasAddressEverBeenRewarded;
    address[] public allAddressThatHaveEverBeenRewarded; 

    mapping(address => uint256) public totalMaintanenceFeesDue;
    mapping(address => uint)  public monthsBehindMaintenanceFeeDueDate;

    /**
     * @dev For addresses that are more than 3 months behind on the maintenance fees, each 
     * each address added here will get luquidated
    */
    address[] internal upForLiquidation; 

    // Stockyard allows the rewardBulls function to be more modular. 
    struct StockyardInfo {
        uint startingIndex;
        uint endingIndex;
        uint256 disperableAmount;
    }

    mapping (uint => StockyardInfo) public stockyardInfo;


    // EXTERNAL NFTS THAT AWARD BTC BULLS WITH USDC
    uint256 public percentToKeepFromExternalNfts = 50;

    
    /*
     * @dev The isEcosystemRole is for other contracts that are allowed to update the USDC for BTC BULL Owners on this contract.
     * @dev The isDefenderRole our openzeppelin Defender account working with autotasks and sentinals.
    */

    mapping(address => bool) public isEcosystemRole;
    mapping(address => bool) public isDefenderRole;


    modifier ADMIN_OR_DEFENDER {
        require(msg.sender == owner() || isDefenderRole[msg.sender] == true, "Caller is not an OWNER OR DEFENDER");
        _;
    }



    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);

    event LoadedFundsIntoStockyard(
        uint stockyardNumber,
        uint256 indexed amountDeposited,
        address indexed sender
    
    );


    event NewBullsEnteringRanch(
        address indexed NewbullOwner,
        bool indexed RaffleEntered,
        uint256  BullsPurchased,
        uint256 _NFTCount
    );

    event dailyRaffleWinnerEvent(
        address indexed raffleWinner,
        uint256  raffleWinAmount

    );
    
    event withdrawUSDCRewardsForAddressEvent(
        address indexed nftOwner,
        uint256 indexed totalAmountTransferred
    );

    event withdrawWbtcRewardsEvent(
        address indexed nftOwner,
        uint256 indexed totalAmountTransferred  
    );

    event liquidationEvent (
        address indexed nftOwner,
        uint256 indexed totalAmountliquidated
    );


    event RewardEvent(
            uint256 totalAmountDispersed,
            uint256 payPerNFT,
            uint indexed startingIndex,
            uint indexed endingIndex
    );


    event MaintenanceFeeUpdatingEvent(
            uint monthlyMaintFee,
            string sectionMessage
    );

    event MaintenanceFeeEvent(
            string sectionMessage
    );

    event payMaintanenceFeesEvent(
            address indexed nftOwner,
            uint256 indexed totalAmountPayedWithCurrentRewards,
            uint256 indexed totalAmountPayedWithoutCurrentRewards
    );



    constructor(
        address _coreTeam_1,
        address _coreTeam_2,
        string memory _initBaseURI,
        address _vrfCoordinatorV2,
        bytes32 _gasLane, // keyHash
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) 
        VRFConsumerBaseV2(_vrfCoordinatorV2)
        ERC721("TheRanch_BTC_BULLS_COMMUNITY", "TRBC") {



        if (address(_coreTeam_1) == address(0)) { revert Address_CantBeAddressZero();}
        if (address(_coreTeam_2) == address(0)) { revert Address_CantBeAddressZero();}
        coreTeam_1 = _coreTeam_1;
        coreTeam_2 = _coreTeam_2;
        
        setBaseURI(_initBaseURI);  
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        gasLane = _gasLane;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;


        // // CoreTeam1 member will be in charge of transferring these NFTs to people helping the project such as multisig help, advertisement, security help.
        // for(uint256 i = 0; i < 15; i++) {
        //     _tokenSupply.increment();
        //     _safeMint(_coreTeam_1, _tokenSupply.current());
        // }

    }


   // MINTING
    /**
     * @dev This is the function does the following things:
     * 0. Only works if the raffle is NOT PROCESSING, This only happens once a day for a small amount of time. 
     * 1. Allows users to mint new NFTs 1 - 10 per tx 
     * 2. Updates Mapping for their total count of mints
     * 3. Uses a referral/partners system to see who gets the referral bonus.
     * 4. Enters user into the daily raffle if they chose to do so. 
     * 5. If msg.sender elects to enter raffle, 95% goes to btcMinersFund, if they do not, 98% does. 
    */
    function mint(uint256 _tokenQuantity, bool _enterRaffle) public payable {
        if (paused) { revert Contract_CurrentlyPaused_CheckSocials();}
        if (!publicSaleLive) { revert Minting_PublicSaleNotLive();}
        if (_tokenQuantity ==  0 || _tokenQuantity > 10) { revert Minting_IsZeroOrBiggerThanTen();}
        // if (_tokenQuantity > 100) {revert Minting_ExceedsMintsPerTx();}
        if (_tokenSupply.current() + _tokenQuantity > maxSupply) {revert Minting_ExceedsTotalBulls();}


        IERC20 mintingToken = IERC20(usdcTokenContract);
        uint256 minting_cost_per_bull = mintingCost * 10 ** usdcTokenDecimals;
        uint256 totalTransactionCost = minting_cost_per_bull * _tokenQuantity;
        mintingToken.safeTransferFrom(msg.sender, address(this), (totalTransactionCost));

        for(uint256 i = 0; i < _tokenQuantity; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }

        //update the mint count for msg.sender
        userMintCount[msg.sender] += _tokenQuantity;

        // Voluntary Raffle entry allow users to enter raffle is they choose too with _enterRaffle == True
        uint256 raffleFundAmt; 

        if (_enterRaffle == true){
            raffleFundAmt = totalTransactionCost * 3 / 100;
            if (getUserAlreadyInDailyRaffleStatus(msg.sender) == false){
                dailyRafflePlayers.push(payable(msg.sender));
                userInDailyRaffle[msg.sender] = true; 
            }
            dailyRaffleBalance += raffleFundAmt;
        } else {
            raffleFundAmt = 0;
        }

        // update contract balances
        uint256 referralFundAmt = totalTransactionCost * 2 / 100;
        uint256 warChestAmt = totalTransactionCost * 5 / 100;
        uint256 btcMinersFundAmt = totalTransactionCost - (referralFundAmt + raffleFundAmt)  - warChestAmt; 
        USDCRewardsBalance += (referralFundAmt + raffleFundAmt);
        btcMinersSafeBalance += btcMinersFundAmt;
        hostingSafeBalance += warChestAmt; 
        
        // update USDC Reward Balances for referrals
        address referrer = myPartner[msg.sender];
        if(referrer != address(0) && userMintCount[referrer] > 0){
            updateUsdcBonus(referrer, referralFundAmt);
        }
        else
        {
            uint256 splitReferralAmt = referralFundAmt * 50 / 100;
            updateUsdcBonus(coreTeam_1, splitReferralAmt);
            updateUsdcBonus(coreTeam_2, splitReferralAmt);
        }
        
        emit NewBullsEnteringRanch(msg.sender,_enterRaffle, _tokenQuantity, _tokenSupply.current());
    }

    function fundBulls(uint _stockyardNumber, uint256 _totalAmountToDeposit) public payable ADMIN_OR_DEFENDER{
        // Transfer rewardTokens to the contract
        if (stockyardInfo[_stockyardNumber].startingIndex == 0) { revert Stockyard_IsNotSetYet();}
        IERC20 tokenContract = IERC20(wbtcTokenContract);
        tokenContract.safeTransferFrom(msg.sender, address(this), _totalAmountToDeposit);

        stockyardInfo[_stockyardNumber].disperableAmount += _totalAmountToDeposit;
        emit LoadedFundsIntoStockyard(_stockyardNumber,_totalAmountToDeposit, msg.sender);
    }


    function rewardBulls(uint _stockyardNumber) public payable ADMIN_OR_DEFENDER {
        if (calculatedMonthlyMaintenanceFee == 0) { revert Rewarding_NotReady();}
        if (stockyardInfo[_stockyardNumber].disperableAmount == 0) { revert Rewarding_NotReady();}
        if (!paused) { revert Pause_MustBePaused();}

        
        // store the 10% Core team values to send later in the function
        uint256 coreTeam_1_amt; 
        uint256 coreTeam_2_amt; 

        uint startingIndex = stockyardInfo[_stockyardNumber].startingIndex;
        uint endingIndex = stockyardInfo[_stockyardNumber].endingIndex;

        uint256 monthlyAmountToDisperse = stockyardInfo[_stockyardNumber].disperableAmount;
    

        coreTeam_1_amt += monthlyAmountToDisperse * coreTeam_1_percent / 100;
        coreTeam_2_amt += monthlyAmountToDisperse * coreTeam_2_percent / 100;


        uint256 _disperableAmount = (monthlyAmountToDisperse * (100 - (coreTeam_1_percent + coreTeam_2_percent)) / 100); 
        uint256 payout_per_nft = _disperableAmount / ((endingIndex - startingIndex) + 1);


        for( uint i = startingIndex; i <= endingIndex; i++) {
            address bullOwner = ownerOf(i);
            if (bullOwner != address(0)){
                if (monthlyMaintanenceFeeDue[bullOwner] == false){
                    monthlyMaintanenceFeeDue[bullOwner] = true;
                    addressesToPayMaintenanceFees.push(bullOwner);
                }

                nftsHeldByAddressAtMonthlyPayout[bullOwner] += 1;

                address referrer = myPartner[bullOwner];
                uint256 referralAmt = payout_per_nft * 1 / 100;
                
                if(referrer != address(0) && userMintCount[referrer] > 0){
                    updateWBTCRewardBalanceForAddress(referrer, referralAmt);
                    updateWBTCRewardBalanceForAddress(bullOwner, (payout_per_nft - referralAmt));
                } else {
                    updateWBTCRewardBalanceForAddress(coreTeam_1, referralAmt);
                    updateWBTCRewardBalanceForAddress(coreTeam_2, referralAmt);
                    updateWBTCRewardBalanceForAddress(bullOwner, (payout_per_nft - (referralAmt * 2)));
                }
            }
        }

        updateWBTCRewardBalanceForAddress(coreTeam_1, coreTeam_1_amt);
        updateWBTCRewardBalanceForAddress(coreTeam_2, coreTeam_2_amt);
    
        emit RewardEvent(monthlyAmountToDisperse, payout_per_nft, startingIndex, endingIndex);

        // reset monthly amount for stockyard
        stockyardInfo[_stockyardNumber].disperableAmount = 0;
    }



 

    // passing a memory array to do this all in one external call
    /**
    * @dev When any other contract in our ecosystem checks the owners of the BTC BullsNFTs, it will updated the USDC amoutn for the 
    * BTC Bulls owner on this contract. It incentives ownership of both NFTS this way: 
    * if the HayBale owner also owns a Bull NFT on this contract, they'll get 100% of the paycut.
    * if the Haybale owner does not own a bull, they will share the paycut 50/50 with CoreTeam_1 
    */
    function updateUsdcBonusFromAnotherContract(address[] memory _ownersOfTheNFTs, uint256 _amountToAdd) external {
        require(isEcosystemRole[msg.sender] == true, "must be approved to interact");

        

        for( uint i; i < _ownersOfTheNFTs.length; i++) {
            address _ownerOfNFT = _ownersOfTheNFTs[i];
            if (balanceOf(_ownerOfNFT) > 0){
                USDCRewardsForAddress[_ownerOfNFT] += _amountToAdd;
            } else {
                uint256 splitBonusAmt = _amountToAdd * 50 / 100;
                USDCRewardsForAddress[_ownerOfNFT] += splitBonusAmt;
                USDCRewardsForAddress[coreTeam_1] += splitBonusAmt;
            }
        }
    }

    function updateMaintenanceFeesForTheMonth() external ADMIN_OR_DEFENDER {
        if (!paused) { revert Maintenance_UpdatingNotReady();}
        if (addressesToPayMaintenanceFees.length < 1) { revert Pause_MustBePaused();}
        
        address[] memory _addressesToPayMaintenanceFees = addressesToPayMaintenanceFees; 

        uint _calculatedMonthlyMaintenanceFee = calculatedMonthlyMaintenanceFee;
        for( uint i; i < _addressesToPayMaintenanceFees.length; i++) {
            address _ownerOfNFTs = _addressesToPayMaintenanceFees[i];
            uint _nftCount = nftsHeldByAddressAtMonthlyPayout[_ownerOfNFTs];


            if (hasAddressEverBeenRewarded[_ownerOfNFTs] == false){
                // update that they have been rewarded before
                hasAddressEverBeenRewarded[_ownerOfNFTs] = true;
                allAddressThatHaveEverBeenRewarded.push(_ownerOfNFTs);
            }
            // update the amount the user owes in maintenance fees because they were rewarded this month.
            totalMaintanenceFeesDue[_ownerOfNFTs] += _nftCount * calculatedMonthlyMaintenanceFee;

            // reset the monthly mapping so they'll be added next month if rewarded again. 
            monthlyMaintanenceFeeDue[_ownerOfNFTs] = false;
            nftsHeldByAddressAtMonthlyPayout[_ownerOfNFTs] = 0;
        }

        // reset calculatedMonthlyMaintenanceFee and addresses found to pay them
        calculatedMonthlyMaintenanceFee = 0;
        addressesToPayMaintenanceFees = new address[](0);

        // emit finishing event
        emit MaintenanceFeeUpdatingEvent(_calculatedMonthlyMaintenanceFee, '_STEP2DONE_ Updated Monthly Fees For Current BTC Bull Owners' );
    }


    function updateMonthsBehindMaintenanceFeeDueDate() external ADMIN_OR_DEFENDER{
        if (!paused) { revert Maintenance_UpdatingNotReady();}

        address[] memory _allAddressThatHaveEverBeenRewarded = allAddressThatHaveEverBeenRewarded; 

        for( uint i; i < _allAddressThatHaveEverBeenRewarded.length; i++) {
            address _address = _allAddressThatHaveEverBeenRewarded[i];
            if (totalMaintanenceFeesDue[_address] > 0) {
                monthsBehindMaintenanceFeeDueDate[_address] += 1;
            }

            // If an _address is more than 3 months behind on maintenance Fees, they will get liquidated
            if (monthsBehindMaintenanceFeeDueDate[_address] == 4){
                upForLiquidation.push(_address);
            }
        }

        // emit event
        emit MaintenanceFeeEvent('_STEP3DONE_ Updated How Many Months Behind For BTC Bull Owners');

    }


    function getLiquidatedArrayLength() public view ADMIN_OR_DEFENDER returns (uint) {
        return upForLiquidation.length;
    }

    function liquidateOutstandingAccounts() external ADMIN_OR_DEFENDER {
        if (!paused) { revert Maintenance_UpdatingNotReady();}
        if (upForLiquidation.length < 1) { revert Liquidation_NothingToDo();}

        uint256 totalAmountLiquidated; 

        for( uint i; i < upForLiquidation.length; i++) {
            address _culprit = upForLiquidation[i];
            uint256 _amount = WBTCRewardsForAddress[_culprit];
            WBTCRewardsForAddress[_culprit] = 0;
            totalAmountLiquidated += _amount; 

            // reset fees and months behind. 
            totalMaintanenceFeesDue[_culprit] = 0;
            monthsBehindMaintenanceFeeDueDate[_culprit] = 0;
            emit liquidationEvent(_culprit, _amount) ;
            
        }

        upForLiquidation = new address[](0);
        IERC20(wbtcTokenContract).safeTransferFrom(address(this), hostingSafe, totalAmountLiquidated);
        
        // emit event
        emit MaintenanceFeeEvent('Finished Liquidated Outstanding Accounts');
    }


    /**
     * @dev If the user has USDC rewards to claim
     * the maintanence fee balance will be deducted from that. 
     * If it doesn't cover the entire maintenance fee cost, 
     * the rest of the amount will be asked to approved and sent to the contract. 
    **/
    function payMaintanenceFees() external nonReentrant {
        uint256 _balance = USDCRewardsForAddress[msg.sender];
        uint256 _feesDue = totalMaintanenceFeesDue[msg.sender];

        if (_balance >= _feesDue){

            USDCRewardsForAddress[msg.sender] -= _feesDue; 
            USDCRewardsForAddress[coreTeam_1] += _feesDue; 

            emit payMaintanenceFeesEvent(msg.sender, _feesDue, 0);
        } else {

            IERC20 mintingToken = IERC20(usdcTokenContract);

            uint256 amt_needed =  _feesDue - _balance;
            mintingToken.safeTransferFrom(msg.sender, address(this), (amt_needed));
            USDCRewardsForAddress[coreTeam_1] += amt_needed; 

            if (_balance > 0){
                USDCRewardsForAddress[msg.sender] -= _balance; 
                USDCRewardsForAddress[coreTeam_1] += _balance; 
            }

            emit payMaintanenceFeesEvent(msg.sender, _balance, amt_needed);
        }

        // reset fees and months behind. 
        totalMaintanenceFeesDue[msg.sender] = 0;
        monthsBehindMaintenanceFeeDueDate[msg.sender] = 0;

    }


    function updateWBTCRewardBalanceForAddress(address _ownerOfNFT, uint256 _amount) internal {
        WBTCRewardsForAddress[_ownerOfNFT] +=  _amount;
    }

    function getWbtcRewardBalanceForAddress() public view returns (uint256) {
        return WBTCRewardsForAddress[msg.sender]; 
    }


    function kickOffDailyRaffle() external ADMIN_OR_DEFENDER {
        paused = !paused;  //Pause contract everytime the raffle happens 
        uint256 requestId = vrfCoordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS_DAILY
        );
        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
     
        // DAILY RAFFLE SECTION // 
        uint256 indexOfWinner = randomWords[0] % dailyRafflePlayers.length;
        address dailYRaffleWinner = dailyRafflePlayers[indexOfWinner];
        uint256 raffleWinningAmount = dailyRaffleBalance; 

        // update the daily raffle winnner balance on reward contract
        updateUsdcBonus(dailYRaffleWinner, dailyRaffleBalance);

        resetUserInDailyRaffle(); // must do before resetting dailyRafflePlayers
        dailyRaffleBalance = 0;  // reset dailyRaffleBalance back to zero after drawing
        dailyRafflePlayers = new address[](0);

        emit dailyRaffleWinnerEvent(dailYRaffleWinner, raffleWinningAmount);

    }
    

    /**
     * @dev Once the raffle winner is picked, we loop through the dailyRafflePlayers
     * and set their booling value back to false so they can enter another raffle 
     * if they choose to mint more NFTs later.
     */
    function resetUserInDailyRaffle() internal {
        for (uint i=0; i< dailyRafflePlayers.length ; i++){
            userInDailyRaffle[dailyRafflePlayers[i]] = false;
        }
    }


    function setPartnerAddress(address _newPartner)  public {
        if (address(_newPartner) == address(0)) { revert Partner_NotAllowed();}
        if (address(_newPartner) == msg.sender) { revert Partner_NotAllowed();}

        address currentPartner = myPartner[msg.sender];
        // myPartner[msg.sender] = _newPartner;

        if (currentPartner == address(0)){
            myPartner[msg.sender] = _newPartner;
            myParnterNetworkTeam[_newPartner] += 1;
        } else {
            myPartner[msg.sender] = _newPartner;
            myParnterNetworkTeam[currentPartner] -= 1;
            myParnterNetworkTeam[_newPartner] += 1;
        }
    }

    // Contract Funding / Withdrawing / Transferring
    function fund() public payable {}

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.safeTransfer(msg.sender, _amount);
    }

    function withdrawBtcMinersSafeBalance() external ADMIN_OR_DEFENDER {
        IERC20 tokenContract = IERC20(usdcTokenContract);
        uint256 amtToTransfer = btcMinersSafeBalance;

        tokenContract.safeTransferFrom(address(this), btcMinersSafe, amtToTransfer);
        btcMinersSafeBalance -= amtToTransfer;

    
    }

    function withdrawHostingSafeBalance() external ADMIN_OR_DEFENDER {
        IERC20 tokenContract = IERC20(usdcTokenContract);
        uint256 amtToTransfer = hostingSafeBalance; 
        tokenContract.safeTransferFrom(address(this), hostingSafe, amtToTransfer);
        hostingSafeBalance -= amtToTransfer;
    }





    function withdrawWbtcForWalletAddress() external nonReentrant {
        if (paused) { revert Contract_CurrentlyPaused_CheckSocials();}
        if (isBlacklisted[msg.sender]) { revert Blacklisted();}

        require(totalMaintanenceFeesDue[msg.sender] == 0, "You must pay maintenance fee balance before WBTC withdrawal is allowed");

        // Get the total Balance to award the owner of the NFT(s)
        uint256 myBalance = WBTCRewardsForAddress[msg.sender];
        if (myBalance == 0) { revert Rewarding_NoBalanceToWithdraw();}

        // Transfer Balance 
        IERC20(wbtcTokenContract).safeTransfer(msg.sender, myBalance );

        // update wbtc balance for nft owner
        WBTCRewardsForAddress[msg.sender] = 0;
        
        emit withdrawWbtcRewardsEvent(msg.sender, myBalance);
    }

    function withdrawUsdcRewardBalance() external nonReentrant {
        if (paused) { revert Contract_CurrentlyPaused_CheckSocials();}
        if (isBlacklisted[msg.sender]) { revert Blacklisted();}
        
        // Get USDC rewards balance for msg.sender
        uint256 myBalance = USDCRewardsForAddress[msg.sender];
        if (myBalance == 0) { revert Rewarding_NoBalanceToWithdraw();}
 
        // Transfer Balance 
        IERC20(usdcTokenContract).safeTransfer(msg.sender, (myBalance));
        // update mapping on contract 
        USDCRewardsForAddress[msg.sender] = 0;
        // update USDC Rewards Balance Total
        USDCRewardsBalance -= myBalance;
        
        // emit event
        emit withdrawUSDCRewardsForAddressEvent(msg.sender, myBalance);
        
    }

    function updateUsdcBonus(address _recipient, uint256 _amountToAdd) internal {
        USDCRewardsForAddress[_recipient] += _amountToAdd;
    }

    function getUsdcRewardBalanceForAddress() public view returns (uint256) {
        return USDCRewardsForAddress[msg.sender];
    }


    /** Getter Functions */

    /**
     * @dev returns how many people are using them as someone as their partner
     */
    function getPartnerNetworkTeamCount(address _adressToCheck) public view returns (uint) {
        return myParnterNetworkTeam[_adressToCheck];
    }

    /**
     * @dev checks if an address is using them as their partner.
     */
    function getAreTheyOnMyPartnerNetworkTeam(address _adressToCheck) public view returns (bool) {
        if (myPartner[_adressToCheck] == msg.sender){
            return true;
        }
        return false;
    }

    /**
    * @dev checks if an address has minted before on the contract.
    */
    function getHaveTheyMintedBefore(address _adressToCheck) external view returns (bool) {
        if (userMintCount[_adressToCheck] > 0){
            return true;
        }
        return false;
    }

    function getMintCountForAddress(address _address) public view returns (uint) {
        return userMintCount[_address];
    }

    function getUserAlreadyInDailyRaffleStatus(address _address) public view returns (bool) {
        return userInDailyRaffle[_address];
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }


    function getNumberOfRafflePlayers() public view returns (uint256) {
        return dailyRafflePlayers.length;
    }   

    function getBlacklistedStatus(address _address) public view returns (bool) {
        return isBlacklisted[_address];
    }

   // METADATA
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    // ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256 royaltyAmount) {
        _tokenId; // silence solc warning
        royaltyAmount = _salePrice * 10 / 100;  // 10%
        return (coreTeam_1, royaltyAmount);
    }


    // Contract Control _ ADMIN ONLY
    function setBaseURI(string memory _newBaseURI) public onlyOwner{
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function togglePublicSaleStatus() external onlyOwner{
        publicSaleLive = !publicSaleLive;
    }

    function togglePauseStatus() external ADMIN_OR_DEFENDER{
        if(address(coreTeam_1) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if(address(coreTeam_2) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if(address(usdcTokenContract) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if(address(wbtcTokenContract) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if(address(hostingSafe) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if(address(btcMinersSafe) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        string memory currentBaseURI = _baseURI();
        if(bytes(currentBaseURI).length == 0) { revert Pause_BaseURIMustBeSetFirst();}

        paused = !paused;
    }

    function setCoreTeamAddresses(
        address _coreTeam_1,
        address _coreTeam_2,
        uint _percent_1,
        uint _percent_2
        ) external onlyOwner {

        if (address(_coreTeam_1 ) == address(0) || address(_coreTeam_2 ) == address(0)) { revert Address_CantBeAddressZero();}
        require(_percent_1 + _percent_2 <= 10, "coreTeam_1 and coreTeam_2 must be 10% or lower");
        coreTeam_1 = _coreTeam_1;
        coreTeam_2 = _coreTeam_2;
        coreTeam_1_percent  = _percent_1;
        coreTeam_2_percent  = _percent_2;
    }


    function setSafeAddresses(address _hostingSafe, address _btcMinersSafe) external onlyOwner {

        if (address(_hostingSafe ) == address(0) || address(_btcMinersSafe ) == address(0)) { revert Address_CantBeAddressZero();}
        hostingSafe = _hostingSafe;
        btcMinersSafe = _btcMinersSafe;
    }

    function setMintingPrice(uint _price) external onlyOwner {
        if (!paused) { revert Pause_MustBePaused();}
        mintingCost = _price;
    }

    function setUsdcTokenAddress(address _address) public onlyOwner {
        if (address(_address ) == address(0)) { revert Address_CantBeAddressZero();}
        usdcTokenContract = _address;
    }

    function setUsdcTokenDecimals(uint _decimals) public  onlyOwner {
        usdcTokenDecimals = _decimals;
    }

    function setWbtcTokenAddress(address _address) public onlyOwner {
        if (address(_address ) == address(0)) { revert Address_CantBeAddressZero();}
        wbtcTokenContract = _address;
    }

    function setWbtcTokenDecimals(uint _decimals) public onlyOwner {
        wbtcTokenDecimals = _decimals;
    }

    function setSubscriptionId(uint64 _subscriptionId) public onlyOwner {
        subscriptionId = _subscriptionId;
    }

    function setGasLane(bytes32 _gasLane) public onlyOwner {
        gasLane = _gasLane;
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) public onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function setVrfCoordinator(VRFCoordinatorV2Interface _vrfCoordinator) public onlyOwner {
        vrfCoordinator = _vrfCoordinator;
    }

    function blacklistMalicious(address _address, bool value) external onlyOwner {
        isBlacklisted[_address] = value;
    }

    function setEcosystemRole(address _address, bool value) external onlyOwner {
        isEcosystemRole[_address] = value;
    }

    function setDefenderRole(address _address, bool value) external onlyOwner {
        isDefenderRole[_address] = value;
    }

    function setMonthlyMaintenanceFeePerNFT(uint256 _monthly_maint_fee_per_nft) external onlyOwner {
        calculatedMonthlyMaintenanceFee = _monthly_maint_fee_per_nft;
    }

    function setStockYardInfo(uint _stockyardNumber, uint256 _startingDisperableAmount, uint _startingIndex, uint _endingIndex) public onlyOwner {
        if (_startingIndex == 0 || _endingIndex == 0 || _stockyardNumber == 0) { revert BadLogicInputParameter();}
        if (_endingIndex > _tokenSupply.current()) { revert BadLogicInputParameter();}
        if (stockyardInfo[_stockyardNumber - 1].endingIndex + 1 != _startingIndex ) { revert BadLogicInputParameter();}
   
        stockyardInfo[_stockyardNumber] =  StockyardInfo(_startingIndex, _endingIndex,_startingDisperableAmount);
    }

    /**
    * @dev This is the amount of rewards thats (percentage) that an owner will keep if they don't own a BTC bull on this contract
    * when theupdateUsdcBonusFromAnotherContract function rewards the current owners of BTC Bulls via another NFT in the ecosystem. 
    */
    function setPercentToKeepFromExternalNfts(uint _percentage) public onlyOwner {
        if (_percentage < 0 || _percentage > 100) { revert BadLogicInputParameter();}
        percentToKeepFromExternalNfts = _percentage;
    }





}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "ERC721.sol";
import "IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}