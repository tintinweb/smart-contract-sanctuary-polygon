// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "IERC721.sol";
import "ReentrancyGuard.sol";

interface FitMintToken {
    function mintTokens(uint256 tokenAmount) external;
}

interface FitMintNFT {
    function mintOGNFT(address userAddress) external;
    function mintNGNFT(address userAddress) external;
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function transferFrom(address fromAddress, address toAddress, uint256 tokenId) external;
}

contract FitMintGameV1 is Ownable, ReentrancyGuard {

    address public tokenAddress;
    address public nftAddress;
    
    //Admin Address with full transfer to tokens/funds
    address public adminAddress;
    uint256 maxMaticWithdrawal = 1e3*1e18;
    mapping(address => uint256) public maxERC20Withdrawal;
    uint256 maxStakingAmount = 1e8*1e18;

    // Reserve Admin Address with limited access to token/funds
    address public reserveAdminAddress;

    FitMintToken gameTokenInstance;
    FitMintNFT gameNFTInstance;    

    mapping(address => uint256) public InGameMaticBalances;
    mapping(address => mapping(address => uint256)) public InGameERC20Balances;
    mapping(address => mapping(uint256 => address)) public InGameERC721Mappings;
    
    event MaticReceived(address _from, uint256 _amount);
    event TransferOfMatic(address _from, address _destAddr, uint256 _amount);
    event TransferOfERC20(address _tokenAddress, address _from, address _destAddr, uint256 _amount);
    event TransferOfERC721(address _tokenAddress, address _from, address _destAddr, uint256 _tokenId);
    

    struct Stake{
        bool stake;
        uint256 amount;
        uint256 since;
    }

    mapping(address => uint256) public StakingBalances;
    mapping(address => Stake []) public StakingHistory;
    address[] public StakedAddresses;
    
    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event UnStaked(address indexed user, uint256 amount, uint256 timestamp);

    event TokenAddressChanged(address oldAddress, address newAddress);
    event NFTAddressChanged(address oldAddress, address newAddress);
    event AdminAddressChanged(address oldAddress, address newAddress);
    event ReserveAdminAddressChanged(address oldAddress, address newAddress);

    event InGameMaticBalanceUpdated(address userAddress, uint256 oldBalance, uint256 newBalance);
    event InGameERC20BalanceUpdated(address userAddress, address tokenAddress, uint256 oldBalance, uint256 newBalance);
    event InGameERC721MappingUpdated(address tokenAddress, uint256 tokenId, address oldAddress, address newAddress);
    
    bool public isInGameDepositActive = false;
    bool public isInGameClaimingActive = false;

    bool public isNFTMintingActive = false;
    bool public isMintingExclusive = false;
    bool public isMintingInGame = false;
    mapping(address => uint8) public _allowOGList;
    mapping(address => uint8) public _allowNGList;
    uint256 public pricePerNGNFT = 0.01 ether;
    uint256 public pricePerOGNFT = 0.01 ether;

    bool public isStakeDepositActive = false;
    bool public isStakeClaimingActive = false;
    uint256 public stakingPenaltyPerc = 0;
    uint256 public stakingCooldownDays = 0;
    mapping(address => uint256) public userCoolDownEndDate;
    
    constructor() public {
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        emit TokenAddressChanged(tokenAddress, _tokenAddress);
        tokenAddress = _tokenAddress;
        gameTokenInstance = FitMintToken(_tokenAddress);
    }

    function setNFTAddress(address _nftAddress) public onlyOwner {
        emit NFTAddressChanged(nftAddress, _nftAddress);
        nftAddress = _nftAddress;
        gameNFTInstance = FitMintNFT(_nftAddress);
    }

    function setAdminAddress(address _adminAddress) public onlyOwner {
        emit AdminAddressChanged(adminAddress, _adminAddress);
        adminAddress = _adminAddress;
    }

    function setReserveAdminAddress(address _reserveAdminAddress) public onlyOwner {
        emit ReserveAdminAddressChanged(reserveAdminAddress, _reserveAdminAddress);
        reserveAdminAddress = _reserveAdminAddress;
    }

    function setMaxMaticWithdrawal(uint256 _maxAmount) public onlyOwner {
        maxMaticWithdrawal = _maxAmount;
    }

    function setMaxERC20Withdrawal(address _tokenAddress, uint256 _maxAmount) public onlyOwner {
        maxERC20Withdrawal[_tokenAddress] = _maxAmount;
    }

    function setMaxStakingAmount(uint256 _maxAmount) public onlyOwner {
        maxStakingAmount = _maxAmount;
    }
    
    function mintFittTokens(uint256 tokenAmount) public onlyOwner{
        gameTokenInstance.mintTokens(tokenAmount);
    }

    function setPricePerNGNFT(uint256 _pricePerNGNFT) public onlyOwner {
       pricePerNGNFT = _pricePerNGNFT;
    }

    function setPricePerOGNFT(uint256 _pricePerOGNFT) public onlyOwner {
       pricePerOGNFT = _pricePerOGNFT;
    }

    function setNFTMintingActive(bool _isNFTMintingActive) external onlyOwner {
        isNFTMintingActive = _isNFTMintingActive;
    }

    function setMintingExclusive(bool _isMintingExclusive) external onlyOwner {
        isMintingExclusive = _isMintingExclusive;
    }

    function setMintingInGame(bool _isMintingInGame) external onlyOwner {
        isMintingInGame = _isMintingInGame;
    }

    function setInGameDepositActive(bool _isInGameDepositActive) external onlyOwner {
        isInGameDepositActive = _isInGameDepositActive;
    }

    function setInGameClaimingActive(bool _isInGameClaimingActive) external onlyOwner {
        isInGameClaimingActive = _isInGameClaimingActive;
    }

    function setStakeDepositActive(bool _isStakeDepositActive) external onlyOwner {
        isStakeDepositActive = _isStakeDepositActive;
    }

    function setStakeClaimingActive(bool _isStakeClaimingActive) external onlyOwner {
        isStakeClaimingActive = _isStakeClaimingActive;
    }

    function setStakingPenaltyPerc(uint256 _stakingPenaltyPerc) external onlyOwner {
        stakingPenaltyPerc = _stakingPenaltyPerc;
    }

    function setStakingCooldownDays(uint256 _stakingCooldownDays) external onlyOwner {
        stakingCooldownDays = _stakingCooldownDays;
    }

    receive() payable external {
        emit MaticReceived(msg.sender, msg.value);
    }
    
    function withdrawMatic(uint256 _amount, address payable _to) external onlyOwner nonReentrant{
        require(address(this).balance >= _amount, "Insufficient Matic in the Game Contract");
        require(_to != address(0), "Cannot withdraw to the zero address");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdrawal of Matic failed.");
        emit TransferOfMatic(address(this), _to, _amount);
    }

    function withdrawERC20(address _tokenAddress, address _to, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount <= IERC20(_tokenAddress).balanceOf(address(this)), "Game Contract does not have requested amount of given ERC20");
        require(_to != address(0), "Cannot transfer ERC20 to the zero address");
        IERC20(_tokenAddress).transfer(_to, _amount);
        emit TransferOfERC20(_tokenAddress, address(this), _to, _amount);
    }

    function withdrawERC721(address _tokenAddress, address _to, uint256 _tokenId) external onlyOwner nonReentrant {
        require(address(this) <= IERC721(_tokenAddress).ownerOf(_tokenId), "Game Contract does not have ERC721 of given tokenId");
        require(_to != address(0), "Cannot transfer ERC721 to the zero address");
        IERC721(_tokenAddress).transferFrom(address(this), _to, _tokenId);
        emit TransferOfERC721(_tokenAddress, address(this), _to, _tokenId);
    }

    function transferMatic(uint256 _amount, address _to) public nonReentrant{
        require(msg.sender == adminAddress, "Only Admin Address can transfer Matic");
        require(_to != address(0), "Cannot transfer Matic to the zero address");
        require(address(this).balance >= _amount, "Insufficient Matic in the Game Contract");
        require(maxMaticWithdrawal >= _amount, "Matic higher than max transfer allowed for admin");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdrawal of Matic failed.");
        emit TransferOfMatic(address(this), _to, _amount);
    }

    function transferERC20Token(address _tokenAddress, address _to, uint256 _tokenAmount) public nonReentrant{
        require(msg.sender == adminAddress, "Only Admin Address can transfer ERC20 tokens");
        require(_to != address(0), "Cannot transfer ERC20 to the zero address");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _tokenAmount, "Game Contract does not have requested amount of given ERC20");
        require(maxERC20Withdrawal[_tokenAddress] >= _tokenAmount, "Amount higher than max transfer allowed for admin");
        IERC20(_tokenAddress).transfer(_to, _tokenAmount);
        emit TransferOfERC20(_tokenAddress, address(this), _to, _tokenAmount);
    }

    function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) public nonReentrant{
        require(msg.sender == adminAddress, "Only Admin Address can transfer ERC721 tokens");
        require(_to != address(0), "Cannot transfer ERC721 to the zero address");
        require(IERC721(_tokenAddress).ownerOf(_tokenId) == address(this), "Game Contract does not have ERC721 of given tokenId");
        IERC721(_tokenAddress).transferFrom(address(this), _to, _tokenId);
        emit TransferOfERC721(_tokenAddress, address(this), _to, _tokenId);
    }

    function transferStaking(address _to, uint256 _stakedAmount) public nonReentrant{
        require(msg.sender == adminAddress, "Only Admin Address can reserve staking balances");
        require(maxStakingAmount >= _stakedAmount, "Admin cannot Stake more max allowed amount for the User");
        if (StakingBalances[_to] == 0){
            StakedAddresses.push(_to);
        }
        StakingBalances[_to] += _stakedAmount;
        uint256 stakedAt = block.timestamp;
        StakingHistory[_to].push(Stake(true, _stakedAmount, stakedAt));
        emit Staked(_to, _stakedAmount, stakedAt);
    }

    function transferUnStaking(address _to, uint256 _unstakedAmount) public nonReentrant{
        require(msg.sender == adminAddress, "Only Admin Address can reserve staking balances");
        require(maxStakingAmount >= _unstakedAmount, "Admin cannot UnStake more max allowed amount for the User");
        StakingBalances[_to] -= _unstakedAmount;
        uint256 withdrawalAt = block.timestamp;
        StakingHistory[_to].push(Stake(false, _unstakedAmount, withdrawalAt));
        emit UnStaked(_to, _unstakedAmount, withdrawalAt);
    }

    function reserveMatic(address _to, uint256 _amount) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only Reserve Admin Address can reserve Matic");
        emit InGameMaticBalanceUpdated(_to, InGameMaticBalances[_to], _amount);
        InGameMaticBalances[_to] = _amount;
    }

    function reserveERC20Token(address _tokenAddress, address _to, uint256 _tokenAmount) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only Reserve Admin Address can reserve ERC20 tokens");
        emit InGameERC20BalanceUpdated(_to, _tokenAddress, InGameERC20Balances[_to][_tokenAddress], _tokenAmount);
        InGameERC20Balances[_to][_tokenAddress] = _tokenAmount;
    }

    function reserveERC721Token(address _tokenAddress, address _to, uint256 _tokenId) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only Reserve Admin Address can reserve ERC721 tokens");
        require(IERC721(_tokenAddress).ownerOf(_tokenId) == address(this), "Game Contract does not have ERC721 of given tokenId");
        emit InGameERC721MappingUpdated(_tokenAddress, _tokenId, InGameERC721Mappings[_tokenAddress][_tokenId], _to);
        InGameERC721Mappings[_tokenAddress][_tokenId] = _to;
    }

    function reserveTransferMatic(uint256 _amount, address _to) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only Reserve Admin Address can transfer Matic");
        require(_to != address(0), "Cannot transfer Matic to the zero address");
        require(address(this).balance >= _amount, "Insufficient Matic in the Game Contract");
        require(InGameMaticBalances[_to] >= _amount, "Insufficient Balance of Matic as per InGame Mappings");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdrawal of Matic failed.");
        emit InGameMaticBalanceUpdated(_to, InGameMaticBalances[_to], InGameMaticBalances[_to] - _amount);
        InGameMaticBalances[_to] -= _amount;
        emit TransferOfMatic(address(this), _to, _amount);
    }

    function reserveTransferERC20Token(address _tokenAddress, address _to, uint256 _tokenAmount) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only Reserve Admin Address can transfer ERC20 tokens");
        require(_to != address(0), "Cannot transfer ERC20 to the zero address");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _tokenAmount, "Game Contract does not have requested amount of given ERC20");
        require(InGameERC20Balances[_to][_tokenAddress] >= _tokenAmount, "Insufficient Balance of ERC20 as per InGame Mappings");
        IERC20(_tokenAddress).transfer(_to, _tokenAmount);
        emit InGameERC20BalanceUpdated(_to, _tokenAddress, InGameERC20Balances[_to][_tokenAddress], InGameERC20Balances[_to][_tokenAddress] - _tokenAmount);
        InGameERC20Balances[_to][_tokenAddress] -= _tokenAmount;
        emit TransferOfERC20(_tokenAddress, address(this), _to, _tokenAmount);
    }

    function reserveTransferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only Reserve Admin Address can transfer ERC721 tokens");
        require(_to != address(0), "Cannot transfer ERC721 to the zero address");
        require(IERC721(_tokenAddress).ownerOf(_tokenId) == address(this), "Game Contract does not have ERC721 of given tokenId");
        require(InGameERC721Mappings[_tokenAddress][_tokenId] == _to, "Different Owner as per InGame Mappings");
        IERC721(_tokenAddress).transferFrom(address(this), _to, _tokenId);
        emit InGameERC721MappingUpdated(_tokenAddress, _tokenId, InGameERC721Mappings[_tokenAddress][_tokenId], address(0));
        InGameERC721Mappings[_tokenAddress][_tokenId] = address(0);
        emit TransferOfERC721(_tokenAddress, address(this), _to, _tokenId);
    }

    function transferNG(address _address) public {
        require(msg.sender == adminAddress, "Only set Admin Address can transfer NG NFT's");
        gameNFTInstance.mintNGNFT(_address);
    }
    
    function transferOG(address _address) public {
        require(msg.sender == adminAddress, "Only set Admin Address can transfer OG NFT's");
        gameNFTInstance.mintOGNFT(_address);
    }

    function reserveNG(address _address) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only set Reserve Admin Address can reserve NG NFT's");
        uint256 totalNFTInContract = gameNFTInstance.balanceOf(address(this));
        gameNFTInstance.mintNGNFT(address(this));
        uint256 newTokenId = gameNFTInstance.tokenOfOwnerByIndex(address(this), totalNFTInContract);
        InGameERC721Mappings[nftAddress][newTokenId] = _address;
        emit InGameERC721MappingUpdated(nftAddress, newTokenId, address(0), _address); 
    }
    
    function reserveOG(address _address) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only set Reserve Admin Address can reserve OG NFT's");
        uint256 totalNFTInContract = gameNFTInstance.balanceOf(address(this));
        gameNFTInstance.mintOGNFT(address(this));
        uint256 newTokenId = gameNFTInstance.tokenOfOwnerByIndex(address(this), totalNFTInContract);
        InGameERC721Mappings[nftAddress][newTokenId] = _address;
        emit InGameERC721MappingUpdated(nftAddress, newTokenId, address(0), _address); 
    }

    function reserveStaking(address _to, uint256 _stakedAmount) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only Reserve Admin Address can reserve staking balances");
        require(InGameERC20Balances[_to][tokenAddress] >= _stakedAmount, "Cannot Stake more than In Game Balance of the User");
        if (StakingBalances[_to] == 0){
            StakedAddresses.push(_to);
        }
        emit InGameERC20BalanceUpdated(_to, tokenAddress, InGameERC20Balances[_to][tokenAddress], InGameERC20Balances[_to][tokenAddress] - _stakedAmount);
        InGameERC20Balances[_to][tokenAddress] -= _stakedAmount;
        StakingBalances[_to] += _stakedAmount;
        uint256 stakedAt = block.timestamp;
        StakingHistory[_to].push(Stake(true, _stakedAmount, stakedAt));
        emit Staked(_to, _stakedAmount, stakedAt);
    }

    function reserveUnStaking(address _to, uint256 _unstakedAmount) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only Reserve Admin Address can reserve staking balances");
        require(_unstakedAmount <= StakingBalances[_to], "Cannot Unstake more than Staking Balance of the User");
        StakingBalances[_to] -= _unstakedAmount;
        emit InGameERC20BalanceUpdated(_to, tokenAddress, InGameERC20Balances[_to][tokenAddress], InGameERC20Balances[_to][tokenAddress] + _unstakedAmount);
        InGameERC20Balances[_to][tokenAddress] += _unstakedAmount;
        uint256 withdrawalAt = block.timestamp;
        StakingHistory[_to].push(Stake(false, _unstakedAmount, withdrawalAt));
        emit UnStaked(_to, _unstakedAmount, withdrawalAt);
    }

    function depositStaking(uint256 _stakedAmount) public nonReentrant{
        require(isStakeDepositActive, "Staking Deposit is not active");
        require(IERC20(tokenAddress).allowance(msg.sender, address(this)) >= _stakedAmount, "Need Approval to the Game Contract to stake FITT tokens");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), _stakedAmount), "Error while transferring FITT tokens");
        if (StakingBalances[msg.sender] == 0){
            StakedAddresses.push(msg.sender);
        }
        StakingBalances[msg.sender] += _stakedAmount;
        uint256 stakedAt = block.timestamp;
        StakingHistory[msg.sender].push(Stake(true, _stakedAmount, stakedAt));
        emit Staked(msg.sender, _stakedAmount, stakedAt);
        userCoolDownEndDate[msg.sender] = stakedAt + stakingCooldownDays * 1 days;
    }

    function claimStaking(uint256 _unstakedAmount, bool payPenatly) public nonReentrant{
        require(isStakeClaimingActive, "Staking Claim is not active");
        require(_unstakedAmount <= StakingBalances[msg.sender], "Cannot Unstake more than Staking Balance of the User");
        if (userCoolDownEndDate[msg.sender] <= block.timestamp){
            require(IERC20(tokenAddress).transfer(msg.sender, _unstakedAmount), "Error while transferring FITT tokens");
            StakingBalances[msg.sender] -= _unstakedAmount;
            uint256 withdrawalAt = block.timestamp;
            StakingHistory[msg.sender].push(Stake(false, _unstakedAmount, withdrawalAt));
            emit UnStaked(msg.sender, _unstakedAmount, withdrawalAt);
        } 
        else{
            require(payPenatly,"User's stake is in cool down period & user is not willing to pay penalty");
            require(IERC20(tokenAddress).transfer(msg.sender, _unstakedAmount - _unstakedAmount * stakingPenaltyPerc / 10000), "Error while transferring FITT tokens");
            StakingBalances[msg.sender] -= _unstakedAmount;
            uint256 withdrawalAt = block.timestamp;
            StakingHistory[msg.sender].push(Stake(false, _unstakedAmount, withdrawalAt));
            emit UnStaked(msg.sender, _unstakedAmount, withdrawalAt);
        }
    }

    function depositInGameMatic() public payable nonReentrant{
        require(isInGameDepositActive, "In Game Deposit Not Active");
        emit InGameMaticBalanceUpdated(msg.sender, InGameMaticBalances[msg.sender], InGameMaticBalances[msg.sender] + msg.value);
        InGameMaticBalances[msg.sender] += msg.value;
    }

    function depositInGameERC20(address _tokenAddress, uint256 _tokenAmount) public nonReentrant{
        require(isInGameDepositActive, "In Game Deposit Not Active");
        require(IERC20(_tokenAddress).allowance(msg.sender, address(this)) >= _tokenAmount, "Need Approval to the Game Contract to deposit given ERC20");
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _tokenAmount), "Transfer of ERC20 from user to Game Contract Failed");
        emit InGameERC20BalanceUpdated(msg.sender, _tokenAddress, InGameERC20Balances[msg.sender][_tokenAddress], InGameERC20Balances[msg.sender][_tokenAddress] + _tokenAmount);
        InGameERC20Balances[msg.sender][_tokenAddress] += _tokenAmount;
    }

    function depositInGameERC721(address _tokenAddress, uint256 _tokenId) public nonReentrant{
        require(isInGameDepositActive, "In Game Deposit Not Active");
        require(IERC721(_tokenAddress).getApproved(_tokenId) == address(this), "Need Approval to the Game Contract to deposit given ERC721");
        IERC721(_tokenAddress).transferFrom(msg.sender, address(this), _tokenId);
        emit InGameERC721MappingUpdated(_tokenAddress, _tokenId, InGameERC721Mappings[_tokenAddress][_tokenId], msg.sender);
        InGameERC721Mappings[_tokenAddress][_tokenId] = msg.sender;
        
    }

    function claimInGameMatic(uint256 _amount) public nonReentrant{
        require(isInGameClaimingActive, "In Game Claim Not Active");
        require(InGameMaticBalances[msg.sender] >= _amount, "Insufficient Matic Balance in In Game Mapping");
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Withdrawal of Matic failed.");
        emit InGameMaticBalanceUpdated(msg.sender, InGameMaticBalances[msg.sender], InGameMaticBalances[msg.sender] - _amount);
        InGameMaticBalances[msg.sender] -= _amount;
    }

    function claimInGameERC20(address _tokenAddress, uint256 _tokenAmount) public nonReentrant{
        require(isInGameClaimingActive, "In Game Claim Not Active");
        require(InGameERC20Balances[msg.sender][_tokenAddress] >= _tokenAmount, "Insufficient ERC20 balance in In Game Mapping");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _tokenAmount, "Game Contract does not have requested amount of given ERC20");
        require(IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount), "Transfer of ERC20 from Game Contract to User Failed");
        emit InGameERC20BalanceUpdated(msg.sender, _tokenAddress, InGameERC20Balances[msg.sender][_tokenAddress], InGameERC20Balances[msg.sender][_tokenAddress] - _tokenAmount);
        InGameERC20Balances[msg.sender][_tokenAddress] -= _tokenAmount;
        emit TransferOfERC20(_tokenAddress, address(this), msg.sender, _tokenAmount);
    }

    function claimInGameERC721(address _tokenAddress, uint256 _tokenId) public nonReentrant{
        require(isInGameClaimingActive, "In Game Claim Not Active");
        require(IERC721(_tokenAddress).ownerOf(_tokenId) == address(this), "Game Contract does not have ERC721 of given tokenId");
        require(InGameERC721Mappings[_tokenAddress][_tokenId] == msg.sender, "Different Owner as per InGame Mappings");        
        IERC721(_tokenAddress).transferFrom(address(this), msg.sender, _tokenId);
        emit InGameERC721MappingUpdated(_tokenAddress, _tokenId, InGameERC721Mappings[_tokenAddress][_tokenId], address(0));
        InGameERC721Mappings[_tokenAddress][_tokenId] = address(0);
        emit TransferOfERC721(_tokenAddress, address(this), msg.sender, _tokenId);
    }

    function reserveNGAllowList(address[] calldata addresses, uint8 numAllowedToMint) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only set Reserve Admin Address can set the NG allow list");
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowNGList[addresses[i]] = numAllowedToMint;
        }
    }

    function reserveOGAllowList(address[] calldata addresses, uint8 numAllowedToMint) public nonReentrant{
        require(msg.sender == reserveAdminAddress, "Only set Reserve Admin Address can set the OG allow list");
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowOGList[addresses[i]] = numAllowedToMint;
        }
    }

    function mintNGNFTwithPolygon() public payable nonReentrant{
        require(isNFTMintingActive, "NFT Minting Active");
        require(msg.value >= pricePerNGNFT, "Native coin send is less than Price of NG NFT");
        if (isMintingExclusive) {
            require(_allowNGList[msg.sender] > 0, "Mintable NFT number not updated in _allowList for the Address");
            _allowNGList[msg.sender] -= 1;
        }

        if (isMintingInGame){
            uint256 totalNFTInContract = gameNFTInstance.balanceOf(address(this));
            gameNFTInstance.mintNGNFT(address(this));
            uint256 newTokenId = gameNFTInstance.tokenOfOwnerByIndex(address(this), totalNFTInContract);
            InGameERC721Mappings[nftAddress][newTokenId] = msg.sender;
        }
        else{
            gameNFTInstance.mintNGNFT(msg.sender);
        }
    }

    function mintOGNFTwithPolygon() public payable nonReentrant{
        require(isNFTMintingActive, "NFT Minting Active");
        require(msg.value >= pricePerOGNFT, "Native coin send is less than Price of OG NFT");
        if (isMintingExclusive) {
            require(_allowOGList[msg.sender] > 0, "Mintable NFT number not updated in _allowList for the Address");
            _allowOGList[msg.sender] -= 1;
        }

        if (isMintingInGame){
            uint256 totalNFTInContract = gameNFTInstance.balanceOf(address(this));
            gameNFTInstance.mintOGNFT(address(this));
            uint256 newTokenId = gameNFTInstance.tokenOfOwnerByIndex(address(this), totalNFTInContract);
            InGameERC721Mappings[nftAddress][newTokenId] = msg.sender;
        }
        else{
            gameNFTInstance.mintOGNFT(msg.sender);
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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