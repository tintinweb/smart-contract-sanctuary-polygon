// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./InviteTypes.sol";
import "./IDEFYGenesisInvite.sol";

// ______ _____________   __
// |  _  \  ___|  ___\ \ / /
// | | | | |__ | |_   \ V /
// | | | |  __||  _|   \ /
// | |/ /| |___| |     | |
// |___/ \____/\_|     \_/
//
// WELCOME TO THE REVOLUTION

// Reading our smart contract hey?  There's a hidden message somewhere on this contract, see if you can find it... ;)

contract DEFYGenesisMask is ERC721, ERC721Enumerable, Pausable, AccessControl, Ownable, InviteTypes, ReentrancyGuard, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    // Roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TOKEN_UNLOCKER_ROLE = keccak256("TOKEN_UNLOCKER_ROLE");
    bytes32 public constant BALANCE_WITHDRAWER_ROLE = keccak256("BALANCE_WITHDRAWER_ROLE");

    // Counters for number of public tokens minted and DEFY admin tokens minted
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _defyTokenIdCounter;

    // Maximum masks to be minted on this contract
    uint256 private constant MAX_MASKS = 8888;

    // Number of masks reserved for DEFY to distribute as prizes
    uint256 private constant DEFY_RESERVED_MASKS = 200;

    // Invite series ids
    uint256 private constant PHASE_ONE_INVITE_SERIES_ID = 0;
    uint256 private constant PHASE_TWO_INVITE_SERIES_ID = 2;

    uint256 private constant PRIZE_MASK_VALUE = 100000;
    uint256 private constant ELITE_MASK_MID_VALUE = 1000;
    uint256 private constant MID_MASK_MID_VALUE = 100;
    uint256 private constant LOW_MASK_MID_VALUE = 10;

    // ChainlinkVRF config values.  Default values set for Polygon mainnet
    VRFCoordinatorV2Interface VRFCOORDINATOR;
    LinkTokenInterface LINKTOKEN;

    uint64 public vrfSubscriptionId;
    bytes32 public vrfKeyHash = 0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8;
    uint32 public vrfCallbackGasLimit = 100000;

    // Types of masks for the purpose of rewards
    // PRIZE_MASK gets 100,000 tokens ($10k worth)
    // ELITE_MASK gets 800-1,200 ($80 - $120 worth)
    // MID_MASK gets 80-120 tokens ($8 - $12 worth)
    // LOW_MASK gets 8-12 tokens ($0.80 - $1.20 worth)
    enum MaskType {
      PRIZE_MASK,
      ELITE_MASK,
      MID_MASK,
      LOW_MASK
    }

    mapping(uint256 => string) private _kha0sMsgs;

    // On-chain metadata, storing the number of bonded tokens and remaining bonded tokens
    struct DEFYGenesisMaskMetadata {
      uint256 totalBondedTokens;
      uint256 remainingBondedTokens;
    }

    // Reference to the genesis invite contract, for validating and spending invites during phase one and two
    IDEFYGenesisInvite public defyGenesisInvite;

    // Base URI for mask token uris
    string private _maskBaseURI;

    // Contract URI. This needs to be set at some point
    string private _contractURI;

    // Price (in MATIC) required to mint a mask
    uint256 public mintPrice;

    // Commission divisor
    uint256 public commissionDivisor;

    // Mapping to keep track of the number of remaining mask types
    mapping(MaskType => uint256) public _remainingMaskTypeAllocation;

    // Tracker of how many tokens have been bonded overall
    uint256 private _totalBondedTokens;

    // Mapping of mask id to on-chain bonded token metadata
    mapping(uint256 => DEFYGenesisMaskMetadata) private _defyGenesisMaskMetadata;

    mapping(uint256 => uint256) private _vrfRequestIdToTokenId;

    // State variables that are used to enable and disable the various minting phases via the below modifiers
    bool public phaseOneActive;
    bool public phaseTwoActive;
    bool public publicMintActive;

    bool public chainlinkVrfActive;

    event MaskTokensAssigned(uint256 tokenId, uint256 amount);
    event MaskTokensUnlocked(uint256 tokenId, uint256 amount);

    modifier whenPhaseOneActive() {
        require(phaseOneActive, 'DGM: Phase 1 not active');
        _;
    }

    modifier whenPhaseTwoActive() {
        require(phaseTwoActive, 'DGM: Phase 2 not active');
        _;
    }

    modifier whenPublicMintActive() {
        require(publicMintActive, 'DGM: Public mint not active');
        _;
    }

    constructor(address vrfCoordinator, address vrfLinkToken) ERC721("DEFYGenesisMask", "DGM") VRFConsumerBaseV2(vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        VRFCOORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(vrfLinkToken);

        // Set up the various mask type allocations
        _remainingMaskTypeAllocation[MaskType.PRIZE_MASK] = 1;
        _remainingMaskTypeAllocation[MaskType.ELITE_MASK] = 1000;
        _remainingMaskTypeAllocation[MaskType.MID_MASK] = 5500;
        _remainingMaskTypeAllocation[MaskType.LOW_MASK] = 2387;

        // Initialise the mint price
        mintPrice = 160 ether;

        // Start the contract with all phases disabled
        phaseOneActive = false;
        phaseTwoActive = false;
        publicMintActive = true;

        // Start contract without ChainlinkVRF
        chainlinkVrfActive = false;

        // Set the default commission divisor to 10 (10%)
        commissionDivisor = 10;

        // Initialise totalBondedTokens
        _totalBondedTokens = 0;

        // Skip mask zero
        _tokenIdCounter.increment();
    }

    /// @notice Allow updating of the ChainlinkVRF parameters
    function updateChainlinkParameters(uint64 newVrfSubscriptionId, bytes32 newVrfKeyHash, uint32 newVrfCallbackGasLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
      vrfSubscriptionId = newVrfSubscriptionId;
      vrfKeyHash = newVrfKeyHash;
      vrfCallbackGasLimit = newVrfCallbackGasLimit;
    }

    /// @notice View the contract URI. This is needed to allow automatic importing of collection metadata on OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Sets the contract URI.
    function setContractURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractURI = uri;
    }

    /// @notice Sets the base URI used for the tokens. This will be updated when new masks are uploaded to IPFS
    function setBaseURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _maskBaseURI = uri;
    }

    /// @notice Get the TokenURI for the supplied token, in the form {baseURI}{tokenId}.json
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "DGM: URI query for nonexistent token");

      return string(abi.encodePacked(_maskBaseURI, Strings.toString(tokenId), '.json'));
    }

    /// @notice Pause the contract, preventing public minting and transfers
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract, allowing public minting and transfers
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Admin function to allow updating of phase one status
    function updatePhaseOneStatus(bool active) public onlyRole(DEFAULT_ADMIN_ROLE) {
      phaseOneActive = active;
    }

    /// @notice Admin function to allow updating of phase two status
    function updatePhaseTwoStatus(bool active) public onlyRole(DEFAULT_ADMIN_ROLE) {
      phaseTwoActive = active;
    }

    /// @notice Admin function to allow updating of public mint status
    function updatePublicMintStatus(bool active) public onlyRole(DEFAULT_ADMIN_ROLE) {
      publicMintActive = active;
    }

    /// @notice Admin function to determine whether ChainlinkVRF is used for randomness of token assignment
    function updateChainlinkVrfActive(bool active) public onlyRole(DEFAULT_ADMIN_ROLE) {
      chainlinkVrfActive = active;
    }

    /// @notice Admin function to allow updating of the mint price
    function updateMintPrice(uint256 newMintPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
      mintPrice = newMintPrice;
    }

    function updateMsg(string memory message, uint256 index) public onlyRole(DEFAULT_ADMIN_ROLE) {
      _kha0sMsgs[index] = message;
    }

    /// @notice Admin function to update the phase 2 commission divisor
    function updatePhaseTwoCommissionDivisor(uint256 newCommissionDivisor) public onlyRole(DEFAULT_ADMIN_ROLE) {
      require(newCommissionDivisor != 0, 'DGM: Cannot set commission divisor to 0');
      commissionDivisor = newCommissionDivisor;
    }

    /// @notice Admin function to allow updating of the connected invite contract address
    function updateInviteContractAddress(address inviteContractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
      defyGenesisInvite = IDEFYGenesisInvite(inviteContractAddress);
    }

    /// @notice Public phase one mint function, allowing holders of a phase 1 invite to mint a mask
    function phaseOneInviteMint(uint256 inviteId)
      public
      payable
      whenNotPaused
      whenPhaseOneActive
      nonReentrant
    {
      require(msg.value == mintPrice, 'DGM: incorrect token amount sent to mint');

      // Get invite metadata from invite contract
      DEFYGenesisInviteMetadata memory inviteMetadata = defyGenesisInvite.getInviteMetadata(inviteId);

      require(inviteMetadata.seriesId == PHASE_ONE_INVITE_SERIES_ID, 'DGM: cannot use invite fron another series for phase 1');

      // Spend the invite. This function will revert the transaction if the invite has already been sent or does not belong to the msg sender
      defyGenesisInvite.spendInvite(inviteId, msg.sender);

      // Mint mask
      _mintMask(msg.sender);
    }

    /// @notice Public phase two mint function, allowing holders of a phase 2 invite to mint a mask. This function also pays a 10% commission to the original holder of the phase 2 invite
    function phaseTwoInviteMint(uint256 inviteId)
      public
      payable
      whenNotPaused
      whenPhaseTwoActive
      nonReentrant
    {
      require(msg.value == mintPrice, 'DGM: incorrect token amount sent to mint');

      // Get invite metadata from invite contract
      DEFYGenesisInviteMetadata memory inviteMetadata = defyGenesisInvite.getInviteMetadata(inviteId);

      require(inviteMetadata.seriesId == PHASE_TWO_INVITE_SERIES_ID, 'DGM: cannot use invite fron another series for phase two');

      // Spend the invite. This function will revert the transaction if the invite has already been sent or does not belong to the msg sender
      defyGenesisInvite.spendInvite(inviteId, msg.sender);

      // Mint mask
      _mintMask(msg.sender);

      // Pay 10% commission to original owner of invite
      (bool success,) = inviteMetadata.originalOwner.call{value : msg.value / commissionDivisor}('');

      require(success, "DEFYGenesisMask: commission payment failed");
    }

    /// @notice Public mint function, does not require the user to hold an invite to mint
    function publicMint()
      public
      payable
      whenNotPaused
      whenPublicMintActive
    {
      require(msg.value == mintPrice, 'DGM: incorrect token amount sent to mint');

      _mintMask(msg.sender);
    }

    function validateCallerLoyalty(uint256 code)
      public
      view
      returns (string memory)
    {
      return _kha0sMsgs[code];
    }

    /// @notice Underlying mint function that checks if there is any allocation remaining and triggers the ChainlinkVRF async function
    function _mintMask(address to) internal {
      uint256 tokenId = _tokenIdCounter.current();
      require(tokenId < (MAX_MASKS - DEFY_RESERVED_MASKS), 'DGM: all public masks minted');

      _tokenIdCounter.increment();
      _safeMint(to, tokenId);

      if (chainlinkVrfActive) {
        submitRequestForRandomness(tokenId);
      } else {
        // Get random numbers
        uint256[] memory randomNumbers = new uint256[](2);
        randomNumbers[0] = random(tokenId);
        randomNumbers[1] = random(tokenId*15231);

        assignRandomTokenAmountToMask(tokenId, randomNumbers);
      }
    }

    /// @notice Admin mask minting function, allowing admins to airdrop masks for free, up to the reserved amount
    function adminMintMask(address to) public onlyRole(MINTER_ROLE) {
      uint256 tokenId = _defyTokenIdCounter.current() + (MAX_MASKS - DEFY_RESERVED_MASKS) ;
      require(tokenId >= MAX_MASKS - DEFY_RESERVED_MASKS, 'DGM: all public masks minted');

      _defyTokenIdCounter.increment();
      _safeMint(to, tokenId);

      if (chainlinkVrfActive) {
        submitRequestForRandomness(tokenId);
      } else {
        // Get random numbers
        uint256[] memory randomNumbers = new uint256[](2);
        randomNumbers[0] = random(tokenId);
        randomNumbers[1] = random(tokenId*15231);

        assignRandomTokenAmountToMask(tokenId, randomNumbers);
      }
    }

    // @notice Admin function to mint the zero mask
    function adminMintZeroMask(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
      require(!_exists(0), 'DGM: zero already minted');

      _safeMint(to, 0);
    }

    // Send request for randomness and store the request id against the token id being minted
    function submitRequestForRandomness(uint256 tokenId) internal {
      uint16 minimumRequestConfirmations = 3;
      uint32 numWords = 2;

      // Kick off randomness request to VRF
      uint256 vrfRequestId = VRFCOORDINATOR.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        minimumRequestConfirmations,
        vrfCallbackGasLimit,
        numWords
      );

      _vrfRequestIdToTokenId[vrfRequestId] = tokenId;
    }

    function random(uint256 seed) private view returns (uint256) {
      return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
    }

    /// @notice callback function from ChainlinkVRF that receives the onchain randomness
    function fulfillRandomWords(
      uint256 requestId,
      uint256[] memory randomWords
    ) internal override(VRFConsumerBaseV2) {
      assignRandomTokenAmountToMask(_vrfRequestIdToTokenId[requestId], randomWords);
    }

    /// @notice assign tokens to the mask using the ChainlinkVRF random words as seeds
    function assignRandomTokenAmountToMask(uint256 tokenId, uint256[] memory randomWords) internal {
      // Check if prize mask still available, and ignore if this is an admin minted mask
      if (_remainingMaskTypeAllocation[MaskType.PRIZE_MASK] > 0 && tokenId < MAX_MASKS - DEFY_RESERVED_MASKS) {
        // Prize is still available, check if it was won
        // Check is done by performing randomValue mod total remaining masks, if value is 0, prize was won
        // This gives you a 1/{remaining masks} chance of winning
        bool won = (randomWords[0] % (MAX_MASKS - DEFY_RESERVED_MASKS - tokenId)) == 0;

        if (won) {
          _defyGenesisMaskMetadata[tokenId].totalBondedTokens = PRIZE_MASK_VALUE;
          _defyGenesisMaskMetadata[tokenId].remainingBondedTokens = PRIZE_MASK_VALUE;
          _remainingMaskTypeAllocation[MaskType.PRIZE_MASK] = 0;
          _totalBondedTokens += PRIZE_MASK_VALUE;

          emit MaskTokensAssigned(tokenId, PRIZE_MASK_VALUE);
          return;
        }
      }

      // No prize mask was won, continuing with award
      MaskType maskType;

      // First 1000 tokens have 50% chance of an elite mask
      if (tokenId < 1000) {
        bool isElite = (randomWords[0] % 2) == 0;

        if (isElite) {
          maskType = MaskType.ELITE_MASK;
        } else {
          maskType = MaskType.MID_MASK;
        }
      } else {
        uint256 totalRemainingMasks = _remainingMaskTypeAllocation[MaskType.ELITE_MASK] + _remainingMaskTypeAllocation[MaskType.MID_MASK] + _remainingMaskTypeAllocation[MaskType.LOW_MASK];

        // Pick random number between 0 and total remaining masks
        uint256 selectedMaskType = randomWords[0] % totalRemainingMasks;

        // Divide remaining masks up across the values, going 0 - remainingElite-1, remainingElite - remainingMid-1, remainingMid - totalRemaining
        // Pick mask type based on the random number selected above
        maskType = selectedMaskType < _remainingMaskTypeAllocation[MaskType.ELITE_MASK] ?
          MaskType.ELITE_MASK :
          (selectedMaskType > totalRemainingMasks - _remainingMaskTypeAllocation[MaskType.LOW_MASK] ?
            MaskType.LOW_MASK :
            MaskType.MID_MASK);
      }

      uint256 rewardAmount;

      // Perform random swing of token value (get total swing range and subtract half to do negative amounts)
      if (maskType == MaskType.ELITE_MASK) {
        uint256 swingValue = (randomWords[1] % 401);
        rewardAmount = ELITE_MASK_MID_VALUE + swingValue - 200;
      } else if (maskType == MaskType.MID_MASK) {
        uint256 swingValue = (randomWords[1] % 41);
        rewardAmount = MID_MASK_MID_VALUE + swingValue - 20;
      } else {
        uint256 swingValue = (randomWords[1] % 5);
        rewardAmount = LOW_MASK_MID_VALUE + swingValue - 2;
      }

      _defyGenesisMaskMetadata[tokenId].totalBondedTokens = rewardAmount;
      _defyGenesisMaskMetadata[tokenId].remainingBondedTokens = rewardAmount;

      _totalBondedTokens += rewardAmount;
      _remainingMaskTypeAllocation[maskType] -= 1;

      emit MaskTokensAssigned(tokenId, rewardAmount);
    }

    /// @notice Get the total assigned tokens for a mask with the provided token id
    function getTotalBondedTokensForMask(uint256 tokenId) public view returns (uint256) {
      require(_exists(tokenId), 'DGM: token does not exist');

      return _defyGenesisMaskMetadata[tokenId].totalBondedTokens;
    }

    /// @notice Get the total remaining bonded tokens for a mask with the provided token id
    function getRemainingBondedTokensForMask(uint256 tokenId) public view returns (uint256) {
      require(_exists(tokenId), 'DGM: token does not exist');

      return _defyGenesisMaskMetadata[tokenId].remainingBondedTokens;
    }

    /// @notice Get the total amount of tokens that have been bonded across all masks on the contract
    function getTotalBondedTokens() public view returns (uint256)
    {
      return _totalBondedTokens;
    }

    /// @notice Function to be called by backend API when bonded token emission events happen in the app
    function unlockBondedTokensFromMask(uint256 tokenId, uint256 tokenAmount) public onlyRole(TOKEN_UNLOCKER_ROLE) {
      require(_exists(tokenId), "DGM: unlocking tokens from nonexistant mask");
      require(tokenAmount < _defyGenesisMaskMetadata[tokenId].remainingBondedTokens, 'DGM: cannot unlock more tokens than remaining on mask');

      _defyGenesisMaskMetadata[tokenId].remainingBondedTokens -= tokenAmount;
    }

    // Prevent token transferring when contract is paused
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Allow contract to receive MATIC directly
    receive() external payable {}

    // Allow withdrawal of the contract's current balance to the caller's address
    function withdrawBalance() public onlyRole(BALANCE_WITHDRAWER_ROLE) {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success, "DGM: Withdrawal failed");
    }

    // Allow withdrawal of the contract's current balance to the caller's address
    function withdrawBalanceExceptFor(uint256 tokens) public onlyRole(BALANCE_WITHDRAWER_ROLE) {
        (bool success,) = msg.sender.call{value : address(this).balance - tokens}('');
        require(success, "DGM: Withdrawal failed");
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}