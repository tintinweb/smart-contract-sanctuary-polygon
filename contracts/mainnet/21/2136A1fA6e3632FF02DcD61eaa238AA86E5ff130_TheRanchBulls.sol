// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ERC721EnumerableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "Initializable.sol";
import "StringsUpgradeable.sol";
import "CountersUpgradeable.sol";
import "SafeERC20Upgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "IERC20Upgradeable.sol";
import "IERC2981Upgradeable.sol";



//........................................................................................................................................................................................................
//........................................................................................................................................................................................................
//........................................................................................................................................................................................................
//........................................................................................................................................................................................................
//........................................................................................................................................................................................................
//............................................................................................................................................................... .'......................................
//............................................................................................................................................................... .dOc....................................
//.................................................................................................................................................................lNWO:..................................
//................................................................................................................................................................ ;XMMNx'................................
//................................................................................................................................................................ ;KMMMW0:...............................
//................................................................................................................................................................ ;KMMMMMXl..............................
//.................................................................................................................................................................cNMMMMMMXc.............................
//............................................................................................................................................................... .xMMMMMMMMK:............................
//...........................,:...................................................................................................................................:XMMMMMMMMMk. ..........................
//..........................:Kx. ................................................................................................................................,0MMMMMMMMMMXc...........................
//.........................lXMk. ...............................................................................................................................;0MMMMMMMMMMMMd. .........................
//........................oNMM0' .................................................................................... .........................................lXMMMMMMMMMMMMMk. .........................
//..................... .lNMMMX:............................................................................. ...';:cc:,. ...................................cOWMMMMMMMMMMMMMMk. .........................
//......................cXMMMMWx. ....................................................................  ...':ldk0XWWMMWXkl'............................ ..;o0WMMMMMMMMMMMMMMMMx. .........................
//.....................;KMMMMMMXc..............................................  .....          ....,:cldk0XWMMMMMMMMMMMMMXkc'...................   ..,cd0NMMMMMMMMMMMMMMMMMMWo...........................
//................... .xWMMMMMMM0,...........................................,codxkkxdoollllllodxk0KNWMMMMMMMMMMMMMMMMMMMMMMWKx;....    .......';:ldkKNMMMMMMMMMMMMMMMMMMMMMMK; ..........................
//....................cXMMMMMMMMWO,.......................................,o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc..;oddxxkOO0KXWWMMMMMMMMMMMMMMMMMMMMMMMMMMNo............................
//.................. .xMMMMMMMMMMW0;.....................................lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:'lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.............................
//.................. '0MMMMMMMMMMMMXo'................................ .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kkOKWNx';0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl. ............................
//.................. ,0MMMMMMMMMMMMMWKo'...............................lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc'.....lXWk';KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,...............................
//.................. ,0MMMMMMMMMMMMMMMWXxc'.........................  .o00KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.........oNWo.kMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd,. ...............................
//.................. .xMMMMMMMMMMMMMMMMMMWXOdl:,......   ........,;:lodxddolcoONMMMMMMMMMMMMMMN0dlcc:cccloxOKNWMMMMMMMMXc......... :XMd;OMMMMMMMMMMMMMMMMMMMMMMMMMN0d:....................................
//....................:XMMMMMMMMMMMMMMMMMMMMMMWNK0OkxdddddxxkO0KKNWMMMMMMMWN0o;:OWMMMMMMMMMMMKc..  ....   ...;0MMMMMMMMNl..........lNXclNMMMMMMMMMMMMMMMMMMMMWXOxl;.......................................
//.....................lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc,kWMMMMMMMMMNl................lNMMMMMMMMXc. ..... ,0Mk;kMMMMMMMMMMMMMMWNKOkol;'...........................................
//......................cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:;KMMMMMMMMMWd. ............. :XMMMMMMMMMNOl;'..,l0WNc:0XXXKK00Okxdoc:;,.... .............................................
//.......................,xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd'kMMMMMMMMMMNl.............. :XMMMMMMMMMMMMNKOkkkkko'.''''.......   .....................................................
//.........................;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd'kMMMMMMMMMMMNd............ .dWMMMMMMMMMMMMMWXKKKK00kdc,....     ........................................................
//......................... .'cx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;'OMMMMMMMMMMMMW0c.. ..... ..oNMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdoollc:,......................................................
//............................ ..,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdl:::xNMMMMMMMWMMMMMMW0dc;;,;:lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOc....................................................
//................................ ...;coxO0XNWMMMMMMMMMMMMMMMMWWNXKOxol:,';lx0NWMMMMMMMMWKKWMMMMMMMMWNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKKNWMMMMMMWOc..................................................
//...................................... ...',;:cllooddddooollc:;,'...  ...:KMMMMMMMMMMMMMNxkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk;,:okKWMMMMWOc. ..............................................
//.............................................               ..............:XMMMMMMMMMMMMMKll0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkollooxkl. ...:dKWMMMWO:..............................................
//......................................................................... .dWMMMMMMMMMMMMMXo;ckKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,.   ...........cOWMMMNk;............................................
//.......................................................................... ;KMMMMMMMMMMMMMMW0o::ldkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:...............c0WMMMXd'..........................................
//.......................................................................... .kMMMWWMMMMMMMMMMMMWXXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l'........'....'xNMMMW0:.........................................
//.......................................................................... .oWMMK0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx:......;kx:'..oNMMMMNo. ......................................
//............................................................................lNMMXx0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o;.. .lNWXkodKMMMMMWd. .....................................
//........................................................................... :XMMWxdNMMMMMMMMMMMMMMMMMMMMNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo:':KMMMMMMMMMMMMXc......................................
//........................................................................... ;KMMM0lOMMMMMMMMMMMMMMMMMMMMKkXMNxlllodxk0XNWMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMWNK0Okkxkk:......................................
//........................................................................... .xWMMNooNMMMMMMMMMMMMMMMMMMMxlKMNd. .  ....,:ldk0XWMMMMMMMMMMMMMMMMMMMMWKxl::clooddxl. .....................................
//..............................................................................dXMMkcOMMMMMMMMMMMMMMMMMMX:'kNMNd;'..  ........';coxOKXWMMMMMMMMMMWXx:''cxKWMMMMMWo.......................................
//...............................................................................,d00clNMMMMMMMMMMMMMMMMWd...,lx0XX0kdlc;'...  ..  ...';clodxkkkxoc,':xKWMMMMMMMWk........................................
//..................................................................................,..xWMMMMMMMMMMMMMMWk' ... ..;lxKNMMNXKOxdlc:;,'...........';cokXWMMMMMMMMMWx'........................................
//......................................................................................dXMMMMMMMMMWX0kl.............;lxKNMMMMMMMWNXK00OOkkkO0KXNWMMMMMMMMMMMW0c..........................................
//.......................................................................................,lxO00kxoc:,................. ..;lxKNMMMMMMMMMMMMMMMMMMMMMMMMMMWN0ko;............................................
//...............................................................................................  ....................... ..;lx0NMMMMMMMMMMMMMMMMWXKOxl:,.. .............................................
//...............................................................................................................................,coxO00KK00Okxdlc;,......................................................
//................................................................................................................................. ............ .........................................................
//........................................................................................................................................................................................................
//........................................................................................................................................................................................................
//........................................................................................................................................................................................................
//........................................................................................................................................................................................................







error Minting_ExceedsTotalBulls();
error Minting_MintingNumberNotAllowed();
error Minting_PublicSaleNotLive();
error Minting_FreeMintsNotLive();
error Minting_AddressNotFreeMintOrAlreadyDone();
error Minting_IsZeroOrBiggerThanMax();
error Pause_MustSetAllVariablesFirst();
error shepherd_NotAllowed();
error shepherd_MutlipleshepherdSwitchesNotAllowed();
error Address_CantBeAddressZero();



/// @custom:security-contact [email protected]
contract TheRanchBulls is 
    Initializable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    IERC2981Upgradeable,
    ReentrancyGuardUpgradeable

    {

    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter public normalTokenSupply;
    CountersUpgradeable.Counter public bronzeTokenSupply;
    CountersUpgradeable.Counter public silverTokenSupply;
    CountersUpgradeable.Counter public goldTokenSupply;

    // token information 
    address public usdcTokenContract; 
    uint256 public usdcTokenDecimals;     
    

    //gnosis-safe addresses
    address public investmentSafe;
    address public marketingSafe;
    address public startupRecoupSafe;
    address public raritySafe;
    address public royaltiesSafe; 
    address public procurementWallet;    // Procurement wallt to purchase alpha Bulls on behalf of investors transferring USD to project.

    mapping (uint256 => uint256) public whitelistBonusAmount;  // bonuses for minting when on the list for it.
    mapping(address => bool) public whitelistMintAddresses;     // all addresses that are given to me via shepherdship deals with other projects
    mapping(address => bool) public addressHasFreeMintLeft;   // all address that are being Free for a single Free BTC Bull mint
    

    uint256 public normalMintStoppingPoint;         // 10,000 is the total it will reach

    mapping(address => uint) public userMintCountForPhase;  // How many bulls did an address mint during the phase
    mapping(address => uint) public userMintCountOverall;  // How many bulls did an address mint overall
    address public phaseMintCountWinner;   // keeps track of who minted the most during a phase the mint winner for the phase
    address public overallMintCountWinner;  // keeps track of overallMintWinner         
    address[] internal mintedDuringPhaseAddresses;      // anyone that minted during the phase. 

    mapping(address => bool) public addressMintedDuringThisPhase;  // Is the person already in the minting Giveaway?
 

    bool public publicSaleLive;
    bool public publicPaperSaleLive;
    bool public freeMintLive;
    bool public alphaBullsMintLive;

    mapping(address => address) public myShepherd;   // shepherd mapping; msg.sender  ==> who referred them
    mapping(address => uint256) public shepherdCount;  // Keeps track of how many people are currently using an address as their shepherd 
        
    mapping(uint256 => address) public indexTiedToShepherd; // perpituity ownership of bringing someone into the project, if someone brings in someone to mint an NFT, save that person's address to that index number. 
    mapping(address => uint256[]) public shepherdIndices; // new mapping to store the indices of the NFTs shepherded by a wallet


    address public topShepherd_1;
    address public topShepherd_2;


    // Contract Balances
    uint256 public investmentSafeBalance;
    uint256 public hostingSafeBalance;     // reserve kept for hosting fees and will be used if people don't pay their maintenance fees on time
    uint256 public marketingSafeBalance;
    uint256 public raritySafeBalance;    // Amount Held for the rarity of the frogs and turtles
    uint256 public startupRecoupSafeBalance;


    enum MintType {BRONZE, SILVER, GOLD, PRESALE1, PRESALE2, PRESALE3, NORMAL, PAPER}
    mapping(MintType => uint256) public mintCost;
    mapping(MintType => uint256) public mintStoppingPoint;
    mapping(MintType => bool) public mintActive;


    // NFT INFO 
    string private baseURI;

    event NewBullsEnteringRanch(
        address indexed newBullOwner,
        uint256  bullsPurchased,
        uint256  NFTCount
    );

    event freeBullsEnteringRanch(
        address indexed newBullOwner,
        uint256  bullGiven
    );

    event phaseWinnerDeclared(
        address indexed bullOwner  
    );

    event overallMintWinnerDeclared(
        address indexed bullOwner  
    );

    event withdrawUSDCBalanceForAddressEvent(
        address indexed nftOwner,
        uint256 indexed totalAmountTransferred
    );

    event alphaBullMinted(
        address indexed NewBullOwner,
        uint256  amountPurchased
    );





    function initialize() public initializer {
        __ERC721_init("The Ranch Bulls Community", "TRBC");
        __ERC721Enumerable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        usdcTokenDecimals = 6;
        publicSaleLive = false;
        publicPaperSaleLive = false;
        freeMintLive = false;


        mintCost[MintType.NORMAL] = 150;
        mintCost[MintType.PAPER] = 180;
        mintCost[MintType.BRONZE] = 350;
        mintCost[MintType.SILVER] = 1000;
        mintCost[MintType.GOLD] =   5000;
        
    
        normalMintStoppingPoint = 250;
        mintStoppingPoint[MintType.NORMAL] = 4891;
        mintStoppingPoint[MintType.BRONZE] = 4958;
        mintStoppingPoint[MintType.SILVER] = 4988;
        mintStoppingPoint[MintType.GOLD] = 4998;



        whitelistBonusAmount[1] = 0;
        whitelistBonusAmount[2] = 0;
        whitelistBonusAmount[3] = 1;
        whitelistBonusAmount[4] = 1;
        whitelistBonusAmount[5] = 2;
        whitelistBonusAmount[6] = 2;
        whitelistBonusAmount[7] = 3;
        whitelistBonusAmount[8] = 3;
        whitelistBonusAmount[9] = 4;
        whitelistBonusAmount[10] = 4;


        bronzeTokenSupply.jumpTo(4900);
        silverTokenSupply.jumpTo(4958);
        goldTokenSupply.jumpTo(4988);
    }


    // MINTING
    /** 
    * @dev The mint function takes in a _tokenQuantity value. 
    */
    function mint(uint256 _tokenQuantity, address _shepherdAddress) public payable {
        if (!publicSaleLive) { revert Minting_PublicSaleNotLive();}
        if (_tokenQuantity > 10) { revert Minting_MintingNumberNotAllowed();}
 
        if( whitelistMintAddresses[msg.sender] == true) {
            if (normalTokenSupply.current() + (_tokenQuantity + whitelistBonusAmount[_tokenQuantity] ) > normalMintStoppingPoint) {revert Minting_ExceedsTotalBulls();}
        } else {
            if (normalTokenSupply.current() + (_tokenQuantity) > normalMintStoppingPoint) {revert Minting_ExceedsTotalBulls();}
        }


        IERC20Upgradeable usdcToken = IERC20Upgradeable(usdcTokenContract);
        uint256 minting_cost_per_Bull = mintCost[MintType.NORMAL] * 10 ** usdcTokenDecimals;

        uint256 totalTransactionCost;
        
        if (whitelistMintAddresses[msg.sender] == true && _tokenQuantity < 3) {
            uint256 _totalTransactionCost = (minting_cost_per_Bull * _tokenQuantity * 8 / 10 );
            totalTransactionCost = _totalTransactionCost;
        } else {
            uint256 _totalTransactionCost = minting_cost_per_Bull * _tokenQuantity;
            totalTransactionCost = _totalTransactionCost;
        }

        usdcToken.safeTransferFrom(msg.sender, address(this), (totalTransactionCost));



        // Handle shepherd address 
        if (_shepherdAddress != address(0)){
            if (myShepherd[msg.sender] == address(0)){
                setShepherdAddress(_shepherdAddress);
            }
        } 

        address currentshepherd = myShepherd[msg.sender];
        
        if( whitelistMintAddresses[msg.sender] == true && whitelistBonusAmount[_tokenQuantity] != 0 ){
            for(uint256 i = 0; i < (_tokenQuantity + whitelistBonusAmount[_tokenQuantity]); i++) {
                normalTokenSupply.increment();
                _safeMint(msg.sender, normalTokenSupply.current());

                if (currentshepherd != address(0)) {
                    indexTiedToShepherd[normalTokenSupply.current()] = currentshepherd; // update this NFT to the indexTiedToShepherd
                    shepherdIndices[currentshepherd].push(normalTokenSupply.current()); // add the tokenId to the array of indices associated with the shepherd's address
                    shepherdCount[currentshepherd] += 1;
                }
            }

            //update the mint count for msg.sender
            userMintCountForPhase[msg.sender] += (_tokenQuantity + whitelistBonusAmount[_tokenQuantity]);
            userMintCountOverall[msg.sender] += (_tokenQuantity + whitelistBonusAmount[_tokenQuantity]);
        } else {
            for(uint256 i = 0; i < _tokenQuantity; i++) {
                normalTokenSupply.increment();
                _safeMint(msg.sender, normalTokenSupply.current());
                
                if (currentshepherd != address(0)) {
                    indexTiedToShepherd[normalTokenSupply.current()] = currentshepherd; // update this NFT to the indexTiedToShepherd
                    shepherdIndices[currentshepherd].push(normalTokenSupply.current()); // add the tokenId to the array of indices associated with the shepherd's address
                    shepherdCount[currentshepherd] += 1;
                }
            }
            //update the mint count for msg.sender
            userMintCountForPhase[msg.sender] += _tokenQuantity;
            userMintCountOverall[msg.sender] += _tokenQuantity;
        }


        // if the user isn't in the addressMintedDuringThisPhase yet, put them in it with a true flag
        if (addressMintedDuringThisPhase[msg.sender] == false){
            mintedDuringPhaseAddresses.push(msg.sender);
            addressMintedDuringThisPhase[msg.sender] = true; 
        }

        if (userMintCountForPhase[msg.sender] > userMintCountForPhase[phaseMintCountWinner]){
            phaseMintCountWinner = msg.sender;
        }

        if (userMintCountOverall[msg.sender] > userMintCountOverall[overallMintCountWinner]){
            overallMintCountWinner = msg.sender;
        }

        // check if currentShepherd is one of the top shepherds
        if (currentshepherd != address(0)) {
            _topShepherdCheck(currentshepherd);
        }
    
        // update contract balances
        uint256 rarityAmt = totalTransactionCost * 5 / 100;
        uint256 marketingSafeAmt = totalTransactionCost * 5 / 100;
        uint256 startupRecoupAmt = totalTransactionCost * 5 / 100;
        uint256 investmentAmt = totalTransactionCost - (rarityAmt + marketingSafeAmt + startupRecoupAmt); 
        investmentSafeBalance += investmentAmt;
        marketingSafeBalance += marketingSafeAmt; 
        raritySafeBalance += rarityAmt;
        startupRecoupSafeBalance += startupRecoupAmt;

        

        if(normalTokenSupply.current() == 250){
            _resetMintingPhaseVariables();
            mintCost[MintType.NORMAL] = 160;
            normalMintStoppingPoint = 650;
            
        }else if(normalTokenSupply.current() == 650){
            _resetMintingPhaseVariables();
            mintCost[MintType.NORMAL] = 170;
            normalMintStoppingPoint = 1200;
        } else if(normalTokenSupply.current() == 1200){
            _resetMintingPhaseVariables();
            mintCost[MintType.NORMAL] = 180;
            normalMintStoppingPoint = 4893;

        } else if(normalTokenSupply.current() == 4893){
            _resetMintingPhaseVariables();
            emit overallMintWinnerDeclared(overallMintCountWinner);
            publicSaleLive = false;
        }

        emit NewBullsEnteringRanch(msg.sender, _tokenQuantity, normalTokenSupply.current());

    }






    function _topShepherdCheck(address _currentShepherd) internal {

        address _topShepherd_1 = topShepherd_1;
        address _topShepherd_2 = topShepherd_2;

        if (shepherdCount[_currentShepherd] > shepherdCount[topShepherd_1]){
            topShepherd_1 = _currentShepherd;
            topShepherd_2 = _topShepherd_1;
        } else if (shepherdCount[_currentShepherd] > shepherdCount[topShepherd_2]) {
            topShepherd_2 = _currentShepherd;
        }
    }









    /**
     * @dev return the total price for the mint transaction and determine if allowed. 
    */
    function getCostAndMintEligibility(address _address, uint256 _tokenQuantity) public view returns (uint256){

        if (_tokenQuantity > 10) { revert Minting_MintingNumberNotAllowed();}
        if (normalTokenSupply.current() + (_tokenQuantity) > normalMintStoppingPoint) {revert Minting_ExceedsTotalBulls();}

        uint256 totalTransactionCost;
        uint256 minting_cost_per_Bull = mintCost[MintType.NORMAL] * 10 ** usdcTokenDecimals;
        
        if (whitelistMintAddresses[_address] == true && _tokenQuantity < 3) {
            uint256 _totalTransactionCost = (minting_cost_per_Bull * _tokenQuantity * 8 / 10 );
            totalTransactionCost = _totalTransactionCost;
        } else {
            uint256 _totalTransactionCost = minting_cost_per_Bull * _tokenQuantity;
            totalTransactionCost = _totalTransactionCost;
        }

        return totalTransactionCost;
    }




    // AlphaBullsMinting on Dapp

    function alphaBullsMintGold(uint256 _tokenQuantity ) public payable {   
        require(alphaBullsMintLive, "Mint not live");
        if (_tokenQuantity ==  0 || _tokenQuantity > 5) { revert Minting_IsZeroOrBiggerThanMax();}

        uint256 costPerMint = mintCost[MintType.GOLD]; 
        uint256 mintStopPoint = mintStoppingPoint[MintType.GOLD];

        require((goldTokenSupply.current() + _tokenQuantity) <= mintStopPoint, "Sold Out");

   
        if(msg.sender != procurementWallet){
            IERC20Upgradeable usdcToken = IERC20Upgradeable(usdcTokenContract);
            uint256 mintingCost = (costPerMint * 10 ** usdcTokenDecimals) * _tokenQuantity;
            usdcToken.safeTransferFrom(msg.sender, procurementWallet, mintingCost);
        }

        address currentshepherd = myShepherd[msg.sender];
    
        for(uint256 i = 0; i < _tokenQuantity; i++) {
            goldTokenSupply.increment();
            _safeMint(msg.sender, goldTokenSupply.current());
            if (currentshepherd != address(0)) {
                // update this NFT to the indexTiedToShepherd
                indexTiedToShepherd[goldTokenSupply.current()] = currentshepherd;
            }
        }
        emit alphaBullMinted(msg.sender, _tokenQuantity);
    }



    function alphaBullsMintSilver(uint256 _tokenQuantity ) public payable {   
        require(alphaBullsMintLive, "Mint not live");
        if (_tokenQuantity ==  0 || _tokenQuantity > 5) { revert Minting_IsZeroOrBiggerThanMax();}

        uint256 costPerMint = mintCost[MintType.SILVER]; 
        uint256 mintStopPoint = mintStoppingPoint[MintType.SILVER];

        require((silverTokenSupply.current() + _tokenQuantity) <= mintStopPoint, "Sold Out");


        if(msg.sender != procurementWallet){
            IERC20Upgradeable usdcToken = IERC20Upgradeable(usdcTokenContract);
            uint256 mintingCost = (costPerMint * 10 ** usdcTokenDecimals) * _tokenQuantity;
            usdcToken.safeTransferFrom(msg.sender, procurementWallet, mintingCost);
        }

        address currentshepherd = myShepherd[msg.sender];
    
        for(uint256 i = 0; i < _tokenQuantity; i++) {
            silverTokenSupply.increment();
            _safeMint(msg.sender, silverTokenSupply.current());
            if (currentshepherd != address(0)) {
                // update this NFT to the indexTiedToShepherd
                indexTiedToShepherd[silverTokenSupply.current()] = currentshepherd;
            }
        }
        emit alphaBullMinted(msg.sender, _tokenQuantity);
    }


    function alphaBullsMintBronze(uint256 _tokenQuantity ) public payable {   
        require(alphaBullsMintLive, "Mint not live");
        if (_tokenQuantity ==  0 || _tokenQuantity > 5) { revert Minting_IsZeroOrBiggerThanMax();}

        uint256 costPerMint = mintCost[MintType.BRONZE]; 
        uint256 mintStopPoint = mintStoppingPoint[MintType.BRONZE];

        require((bronzeTokenSupply.current() + _tokenQuantity) <= mintStopPoint, "Sold Out");


        if(msg.sender != procurementWallet){
            IERC20Upgradeable usdcToken = IERC20Upgradeable(usdcTokenContract);
            uint256 mintingCost = (costPerMint * 10 ** usdcTokenDecimals) * _tokenQuantity;
            usdcToken.safeTransferFrom(msg.sender, procurementWallet, mintingCost);
        }

        address currentshepherd = myShepherd[msg.sender];
    
        for(uint256 i = 0; i < _tokenQuantity; i++) {
            bronzeTokenSupply.increment();
            _safeMint(msg.sender, bronzeTokenSupply.current());
            if (currentshepherd != address(0)) {
                // update this NFT to the indexTiedToShepherd
                indexTiedToShepherd[bronzeTokenSupply.current()] = currentshepherd;
            }
        }
        emit alphaBullMinted(msg.sender, _tokenQuantity);
    }



    // paper.xyz minting

    // Normal Bulls

    function paperMintNormal(address _address, uint256 _tokenQuantity) public payable {
        if (!publicPaperSaleLive) { revert Minting_PublicSaleNotLive();}
        if (_tokenQuantity ==  0 || _tokenQuantity > 10) { revert Minting_IsZeroOrBiggerThanMax();}
        if (normalTokenSupply.current() + _tokenQuantity  > normalMintStoppingPoint) {revert Minting_ExceedsTotalBulls();}


        IERC20Upgradeable usdcToken = IERC20Upgradeable(usdcTokenContract);
        uint256 minting_cost_per_Bull = mintCost[MintType.NORMAL] * 10 ** usdcTokenDecimals;
        uint256 totalTransactionCost = minting_cost_per_Bull * _tokenQuantity;
        usdcToken.safeTransferFrom(_address, address(this), (totalTransactionCost));

        address currentshepherd = myShepherd[msg.sender];

        for(uint256 i = 0; i < _tokenQuantity; i++) {
            normalTokenSupply.increment();
            _safeMint(_address, normalTokenSupply.current());
            if (currentshepherd != address(0)) {
                // update this NFT to the indexTiedToShepherd
                indexTiedToShepherd[normalTokenSupply.current()] = currentshepherd;
            }
        }

        // update contract balances
        uint256 rarityAmt = totalTransactionCost * 5 / 100;
        uint256 marketingSafeAmt = totalTransactionCost * 5 / 100;
        uint256 investmentAmt = totalTransactionCost - (rarityAmt + marketingSafeAmt); 
        investmentSafeBalance += investmentAmt;
        marketingSafeBalance += marketingSafeAmt; 
        raritySafeBalance += rarityAmt;
  
        emit NewBullsEnteringRanch(_address, _tokenQuantity, normalTokenSupply.current());
    }


    function checkClaimEligibilityNormal(uint256 quantity) external view returns (string memory){
        if (!publicPaperSaleLive) {
            return "Minting is not live";
        } else if (quantity > 10) {
            return "max mint amount per transaction exceeded";
        } else if (normalTokenSupply.current()  + quantity > normalMintStoppingPoint) {

            return "not enough supply left";
        }
        return "";
    }


    // BRONZE

    function alphaBullsMintBronzePaper(address _address, uint256 _tokenQuantity) public payable {

        require(alphaBullsMintLive, "Mint not live");
        if (_tokenQuantity ==  0 || _tokenQuantity > 5) { revert Minting_IsZeroOrBiggerThanMax();}

        uint256 costPerMint = mintCost[MintType.BRONZE]; 
        uint256 mintStopPoint = mintStoppingPoint[MintType.BRONZE];

        require((bronzeTokenSupply.current() + _tokenQuantity) <= mintStopPoint, "Sold Out");

        IERC20Upgradeable usdcToken = IERC20Upgradeable(usdcTokenContract);
        uint256 mintingCost = (costPerMint * 10 ** usdcTokenDecimals) * _tokenQuantity;
     
        usdcToken.safeTransferFrom(_address, procurementWallet, mintingCost);

        address currentshepherd = myShepherd[msg.sender];
    
        for(uint256 i = 0; i < _tokenQuantity; i++) {
            bronzeTokenSupply.increment();
            _safeMint(_address, bronzeTokenSupply.current());
            if (currentshepherd != address(0)) {
                // update this NFT to the indexTiedToShepherd
                indexTiedToShepherd[bronzeTokenSupply.current()] = currentshepherd;
            }
        }

        emit alphaBullMinted(_address, _tokenQuantity);
    }




    function checkClaimEligibilityBronze(uint256 quantity) external view returns (string memory){
        if (!alphaBullsMintLive) {
            return "Minting is not live";
        } else if (quantity > 5) {
            return "max mint amount per transaction exceeded";
        } else if (bronzeTokenSupply.current() + quantity > mintStoppingPoint[MintType.BRONZE]) {
            return "not enough supply left";
        }
        return "";
    }



    // SILVER

    function alphaBullsMintSilverPaper(address _address, uint256 _tokenQuantity) public payable {

        require(alphaBullsMintLive, "Mint not live");
        if (_tokenQuantity ==  0 || _tokenQuantity > 5) { revert Minting_IsZeroOrBiggerThanMax();}

        uint256 costPerMint = mintCost[MintType.SILVER]; 
        uint256 mintStopPoint = mintStoppingPoint[MintType.SILVER];

        require((silverTokenSupply.current() + _tokenQuantity) <= mintStopPoint, "Sold Out");

        IERC20Upgradeable usdcToken = IERC20Upgradeable(usdcTokenContract);
        uint256 mintingCost = (costPerMint * 10 ** usdcTokenDecimals) * _tokenQuantity;
     
        usdcToken.safeTransferFrom(_address, procurementWallet, mintingCost);

        address currentshepherd = myShepherd[msg.sender];
    
        for(uint256 i = 0; i < _tokenQuantity; i++) {
            silverTokenSupply.increment();
            _safeMint(_address, silverTokenSupply.current());
            if (currentshepherd != address(0)) {
                // update this NFT to the indexTiedToShepherd
                indexTiedToShepherd[silverTokenSupply.current()] = currentshepherd;
            }
        }

        emit alphaBullMinted(_address, _tokenQuantity);
    }



    function checkClaimEligibilitySilver(uint256 quantity) external view returns (string memory){
        if (!alphaBullsMintLive) {
            return "Minting is not live";
        } else if (quantity > 5) {
            return "max mint amount per transaction exceeded";
        } else if (silverTokenSupply.current() + quantity > mintStoppingPoint[MintType.SILVER]) {
            return "not enough supply left";
        }
        return "";
    }




    /**
     * @dev allows owner to mint the phaseCountWinner TR Bulls (7 Frogs and Turtles purposely set at the high 4890's indexes)
    */
    function phaseWinnerMints() public onlyOwner {
      
        uint256 startingIndex = 4894;

        for(uint256 i = 0; i < 7; i++) {
            _safeMint(msg.sender, startingIndex + i);
        }        
    }

   /**
     * @dev allows owner to mint the phaseCountWinner TR Bulls (7 Frogs and Turtles purposely set at the high 4890's indexes)
    */
    function founderMints() public onlyOwner {
      
        uint256 startingIndex = 4999;

        for(uint256 i = 0; i < 2; i++) {
            _safeMint(msg.sender, startingIndex + i);
        }        
    }


    /**
     * @dev allows addresses to get 1 free 'normal' TR Bull mint if they won a contest or trivia leading up the minting phases. 
    */
    function freeMint() public nonReentrant{
        if (!freeMintLive) { revert Minting_FreeMintsNotLive();}
        if (normalTokenSupply.current() > normalMintStoppingPoint) {revert Minting_ExceedsTotalBulls();}
        if (addressHasFreeMintLeft[msg.sender] == false){ revert Minting_AddressNotFreeMintOrAlreadyDone();}


        uint256 BullIndex = normalTokenSupply.current() + 1;

        normalTokenSupply.increment();
        _safeMint(msg.sender, normalTokenSupply.current());
        addressHasFreeMintLeft[msg.sender] = false;

        emit freeBullsEnteringRanch(msg.sender, BullIndex);
    }


    // Raffle minting for Normal Bulls

    function raffleMint(address _address, uint256 _tokenQuantity) public payable {
        if (!publicSaleLive) { revert Minting_PublicSaleNotLive();}
        if (_tokenQuantity ==  0 || _tokenQuantity > 10) { revert Minting_IsZeroOrBiggerThanMax();}
        if (normalTokenSupply.current() + _tokenQuantity  > normalMintStoppingPoint) {revert Minting_ExceedsTotalBulls();}
        require(msg.sender == procurementWallet, "Not authorized to call");
 
        address currentshepherd = myShepherd[_address];

        for(uint256 i = 0; i < _tokenQuantity; i++) {
            normalTokenSupply.increment();
            _safeMint(_address, normalTokenSupply.current());
            if (currentshepherd != address(0)) {
                // update this NFT to the indexTiedToShepherd
                indexTiedToShepherd[normalTokenSupply.current()] = currentshepherd;
            }
        }
        emit NewBullsEnteringRanch(_address, _tokenQuantity, normalTokenSupply.current());
    }


    // Contract Funding / Withdrawing / Transferring
    function fund() public payable {}

 
    function withdrawToken(address _tokenContract) external onlyOwner {
        IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenContract);
        uint256 _amt;
        if (_tokenContract == usdcTokenContract){
            _amt = tokenContract.balanceOf(address(this)) - (investmentSafeBalance  + marketingSafeBalance + raritySafeBalance );
        } else {
            _amt = tokenContract.balanceOf(address(this));
        }
        tokenContract.safeTransfer(msg.sender, _amt);
    }




   function withdrawInvestmentSafe() external onlyOwner {

        IERC20Upgradeable tokenContract = IERC20Upgradeable(usdcTokenContract); 
        uint256 _amountToTransfer = investmentSafeBalance;
        tokenContract.approve(address(this), _amountToTransfer);
        tokenContract.safeTransferFrom(address(this), investmentSafe, _amountToTransfer);
        investmentSafeBalance -= _amountToTransfer;
    }

 

    function withdrawMarketingSafe() external onlyOwner {
             
        IERC20Upgradeable tokenContract = IERC20Upgradeable(usdcTokenContract); 
        uint256 _amountToTransfer = marketingSafeBalance;
        tokenContract.approve(address(this), _amountToTransfer);
        tokenContract.safeTransferFrom(address(this), marketingSafe, _amountToTransfer);
        marketingSafeBalance -= _amountToTransfer;
    }


    function withdrawRaritySafe() external onlyOwner {

        IERC20Upgradeable tokenContract = IERC20Upgradeable(usdcTokenContract); 
        uint256 _amountToTransfer = raritySafeBalance ;
        tokenContract.approve(address(this), _amountToTransfer);
        tokenContract.safeTransferFrom(address(this), raritySafe, _amountToTransfer);
        raritySafeBalance -= _amountToTransfer;
    }

    function withdrawStartupRecoupSafe() external onlyOwner {

        IERC20Upgradeable tokenContract = IERC20Upgradeable(usdcTokenContract); 
        uint256 _amountToTransfer = startupRecoupSafeBalance ;
        tokenContract.approve(address(this), _amountToTransfer);
        tokenContract.safeTransferFrom(address(this), startupRecoupSafe, _amountToTransfer);
        startupRecoupSafeBalance -= _amountToTransfer;
    }


    /**
     * @dev allows addresses to mint with a burner wallet and then transfer all shepherd indexes to another wallet in the future. 
    */
    function updateShepherd(address _newShepherd) external {
  
        require(shepherdIndices[msg.sender].length > 0, "Nothing to do here, no Bulls under the care of this Shepherd");
        require(_newShepherd != address(0), "Not allowed to pass herd to address(0)");
        
        // Get the current shepherd's indices
        uint256[] storage indices = shepherdIndices[msg.sender];

        // Loop through all the indices and update the shepherd address
        for (uint256 i = 0; i < indices.length; i++) {
            uint256 index = indices[i];
            indexTiedToShepherd[index] = _newShepherd;
            shepherdIndices[_newShepherd].push(index); 
        }
        // delete all indeces from the old address
        delete shepherdIndices[msg.sender];
    }



    /** Getter Functions */
    function getNormalMintingCost() public view returns (uint256) {
        return mintCost[MintType.NORMAL] ;
    }

    function getBronzeMintingCost() public view returns (uint256) {
        return mintCost[MintType.BRONZE] ;
    }

    function getSilverMintingCost() public view returns (uint256) {
        return mintCost[MintType.SILVER] ;
    }

    function getGoldMintingCost() public view returns (uint256) {
        return mintCost[MintType.GOLD] ;
    }


    function getShepherdIndices(address shepherd) public view returns (uint256[] memory) {
        return shepherdIndices[shepherd];
    }


    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

   // METADATA
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    

    /**
     * @dev allow a user to set their shepherd address. If alice sets bob as her shepherd, Bob gets blocked from setting alice. 
    */
    function setShepherdAddress(address _newshepherd)  public {
        if (address(_newshepherd) == address(0)) { revert shepherd_NotAllowed();}
        if (address(_newshepherd) == msg.sender) { revert shepherd_NotAllowed();}
        if (myShepherd[_newshepherd] == msg.sender) { revert shepherd_NotAllowed();}

        address currentshepherd = myShepherd[msg.sender];
    
        if (currentshepherd == address(0)){
            myShepherd[msg.sender] = _newshepherd;
        } else {
            revert shepherd_MutlipleshepherdSwitchesNotAllowed();
        }
    }



    /**
     * @dev 1 == publicSaleLive
     *      2 == publicPaperSaleLive
     *      3 == freeMintLive
     *      4 == alphaBullsMintLive
    */

    function setVariableStatus(uint256 _target, bool _bool) external onlyOwner{
        if (address(investmentSafe) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if (address(marketingSafe) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if (address(raritySafe) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if (address(royaltiesSafe) == address(0)) { revert Pause_MustSetAllVariablesFirst();}
        if (address(procurementWallet) == address(0)) { revert Pause_MustSetAllVariablesFirst();}

        if(_target == 1){
            publicSaleLive = _bool ;
        } else if (_target == 2){
            publicPaperSaleLive = _bool; 
        } else if (_target == 3){
            freeMintLive = _bool;
        } else if (_target == 4){
            alphaBullsMintLive = _bool;
        }
    }


    function setSafeAddresses(
        address _investmentSafe,
        address _marketingSafe,
        address _startupRecoupSafe,
        address _raritySafe,
        address _royaltiesSafe,
        address _procurementWallet,
        address _usdcContract,
        string  memory _newBaseURI

        ) external onlyOwner {

        investmentSafe = _investmentSafe;
        marketingSafe = _marketingSafe;
        startupRecoupSafe = _startupRecoupSafe;
        raritySafe = _raritySafe;
        royaltiesSafe = _royaltiesSafe;
        procurementWallet = _procurementWallet;
        usdcTokenContract = _usdcContract;
        baseURI = _newBaseURI;
    }



    // Free function 
    function addOrRemoveAddressesFreeMint(address[] calldata _users, bool _bool) external onlyOwner {
        for (uint256 i=0; i< _users.length ; i++){
            addressHasFreeMintLeft[_users[i]] = _bool;
        }
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }



    /**
    * @dev Once the phase winner is picked, we loop through the phaseMinters
    * and set their booling value back to false so they can enter another Giveaway 
    * if they choose to mint more NFTs later on a different day.
    */
    function _resetMintingPhaseVariables() internal {

        emit phaseWinnerDeclared(phaseMintCountWinner);

        delete phaseMintCountWinner;

        for (uint256 i=0; i< mintedDuringPhaseAddresses.length ; i++){ 
            addressMintedDuringThisPhase[mintedDuringPhaseAddresses[i]] = false;
            userMintCountForPhase[mintedDuringPhaseAddresses[i]] = 0;
        }

        mintedDuringPhaseAddresses = new address[](0);
    }


    function addOrRemoveWhitelistMintAddresses(address[] calldata _users, bool _bool) external onlyOwner {
        for (uint256 i=0; i< _users.length ; i++){
            whitelistMintAddresses[_users[i]] = _bool;
        }
    }


    //ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableUpgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    // IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256 royaltyAmount) {
        _tokenId;  //silence solc warning
        royaltyAmount = _salePrice * 10 / 100;  // 10%
        return (royaltiesSafe, royaltyAmount);
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "ERC721Upgradeable.sol";
import "IERC721EnumerableUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721Upgradeable.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "IERC721Upgradeable.sol";
import "IERC721ReceiverUpgradeable.sol";
import "IERC721MetadataUpgradeable.sol";
import "AddressUpgradeable.sol";
import "ContextUpgradeable.sol";
import "StringsUpgradeable.sol";
import "ERC165Upgradeable.sol";
import "Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _afterTokenTransfer(address(0), to, tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";
import "Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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
    
    function jumpTo(Counter storage counter, uint256 _valueToJumpTo) internal {
        require(_valueToJumpTo > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = _valueToJumpTo;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "draft-IERC20PermitUpgradeable.sol";
import "AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}