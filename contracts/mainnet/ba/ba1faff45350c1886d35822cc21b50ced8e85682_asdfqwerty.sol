/**
 *Submitted for verification at polygonscan.com on 2022-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Receiver {
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {return this.onERC721Received.selector;}}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {return interfaceId == type(IERC165).interfaceId;}}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0";}
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {digits++; temp /= 10;}
        bytes memory buffer = new bytes(digits);
        while (value != 0) {digits -= 1; buffer[digits] = bytes1(uint8(48 + uint256(value % 10))); value /= 10;}return string(buffer);}

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0x00";}
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {length++; temp >>= 8;} return toHexString(value, length);}

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {buffer[i] = _HEX_SYMBOLS[value & 0xf]; value >>= 4;}
        require(value == 0, "Hex Length Insufficient");
        return string(buffer);}}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {_name = name_; _symbol = symbol_;}
    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) {return 18;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {_transfer(_msgSender(), recipient, amount); return true;}
    function allowance(address owner, address spender) public view virtual override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public virtual override returns (bool) {_approve(_msgSender(), spender, amount); return true;}
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {_transfer(sender, recipient, amount); uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance"); unchecked {_approve(sender, _msgSender(), currentAllowance - amount);} return true;}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue); return true;}
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero"); unchecked {_approve(_msgSender(), spender, currentAllowance - subtractedValue);} return true;}
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address"); _beforeTokenTransfer(sender, recipient, amount); uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance"); unchecked {_balances[sender] = senderBalance - amount;} _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount); _afterTokenTransfer(sender, recipient, amount);}
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to the zero address"); _beforeTokenTransfer(address(0), account, amount); _totalSupply += amount; _balances[account] += amount;
        emit Transfer(address(0), account, amount); _afterTokenTransfer(address(0), account, amount);}
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from the zero address"); _beforeTokenTransfer(account, address(0), amount); uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance"); unchecked {_balances[account] = accountBalance - amount;} _totalSupply -= amount;
        emit Transfer(account, address(0), amount); _afterTokenTransfer(account, address(0), amount);}
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address"); _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);}
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}}

contract asdfqwerty is ERC20, ERC721Holder {
    address public Owner;
    uint256 public maxSupply = 100000000 * 10 ** 18;
    bool private paused;

    address public AddressC1;
    address public AddressC2;
    address public AddressC3;
    address public AddressC4;
    address public AddressC5;

    uint256 public BlocksPerRewardC1;
    uint256 public BlocksPerRewardC2;
    uint256 public BlocksPerRewardC3;
    uint256 public BlocksPerRewardC4;
    uint256 public BlocksPerRewardC5;

    uint256 public TokenPerRewardC1;
    uint256 public TokenPerRewardC2;
    uint256 public TokenPerRewardC3;
    uint256 public TokenPerRewardC4;
    uint256 public TokenPerRewardC5;

    uint256 public MembersC1;
    uint256 public MembersC2;
    uint256 public MembersC3;
    uint256 public MembersC4;
    uint256 public MembersC5;

    uint256 public NFTSC1;
    uint256 public NFTSC2;
    uint256 public NFTSC3;
    uint256 public NFTSC4;
    uint256 public NFTSC5;

    uint256 public StartBlockC1;
    uint256 public StartBlockC2;
    uint256 public StartBlockC3;
    uint256 public StartBlockC4;
    uint256 public StartBlockC5;

    event RewardedC1 (address Member, uint256 Amount);
    event RewardedC2 (address Member, uint256 Amount);
    event RewardedC3 (address Member, uint256 Amount);
    event RewardedC4 (address Member, uint256 Amount);
    event RewardedC5 (address Member, uint256 Amount);

    event NFTStakedC1 (address Member, uint256 TokenId);
    event NFTStakedC2 (address Member, uint256 TokenId);
    event NFTStakedC3 (address Member, uint256 TokenId);
    event NFTStakedC4 (address Member, uint256 TokenId);
    event NFTStakedC5 (address Member, uint256 TokenId);

    event NFTUnstakedC1 (address Member, uint256 TokenId);
    event NFTUnstakedC2 (address Member, uint256 TokenId);
    event NFTUnstakedC3 (address Member, uint256 TokenId);
    event NFTUnstakedC4 (address Member, uint256 TokenId);
    event NFTUnstakedC5 (address Member, uint256 TokenId);

    event OwnershipTransferred(address LastOwner, address NewOwner);
    event Paused();
    event Unpaused();

    modifier OnlyOwner() {require(address(msg.sender) == Owner, "Not Owner"); _;}
    modifier WhenNotPaused() {require(paused == false, "Paused"); _;}
    modifier WhenPaused() {require(paused == true, "Not Paused");_;}

    struct StakeC1 {uint256 StakedBlock; uint256 lastHarvestBlock; bool IsStaked;}
    struct StakeC2 {uint256 StakedBlock; uint256 lastHarvestBlock; bool IsStaked;}
    struct StakeC3 {uint256 StakedBlock; uint256 lastHarvestBlock; bool IsStaked;}
    struct StakeC4 {uint256 StakedBlock; uint256 lastHarvestBlock; bool IsStaked;}
    struct StakeC5 {uint256 StakedBlock; uint256 lastHarvestBlock; bool IsStaked;}

    mapping (address => mapping(uint256 => StakeC1)) public stakeLogC1;
    mapping (address => mapping(uint256 => StakeC2)) public stakeLogC2;
    mapping (address => mapping(uint256 => StakeC3)) public stakeLogC3;
    mapping (address => mapping(uint256 => StakeC4)) public stakeLogC4;
    mapping (address => mapping(uint256 => StakeC5)) public stakeLogC5;

    mapping (address => uint256) public NFTSOfMemberC1;
    mapping (address => uint256) public NFTSOfMemberC2;
    mapping (address => uint256) public NFTSOfMemberC3;
    mapping (address => uint256) public NFTSOfMemberC4;
    mapping (address => uint256) public NFTSOfMemberC5;

    mapping (address => uint256[]) public PortfolioByMemberC1;
    mapping (address => uint256[]) public PortfolioByMemberC2;
    mapping (address => uint256[]) public PortfolioByMemberC3;
    mapping (address => uint256[]) public PortfolioByMemberC4;
    mapping (address => uint256[]) public PortfolioByMemberC5;

    mapping(uint256 => uint256) public indexOfTokenIdInPortfolioC1;
    mapping(uint256 => uint256) public indexOfTokenIdInPortfolioC2;
    mapping(uint256 => uint256) public indexOfTokenIdInPortfolioC3;
    mapping(uint256 => uint256) public indexOfTokenIdInPortfolioC4;
    mapping(uint256 => uint256) public indexOfTokenIdInPortfolioC5;

    constructor() ERC20("FROST", "FROST"){
        Owner = 0x76588bc3f0e2997d66ABCF7aF9808196C556467C;
        AddressC1 = 0x0000000000000000000000000000000000000000;
        AddressC2 = 0x0000000000000000000000000000000000000000;
        AddressC3 = 0x0000000000000000000000000000000000000000;
	    AddressC4 = 0x0000000000000000000000000000000000000000;
        AddressC5 = 0x0000000000000000000000000000000000000000;
        _mint(Owner, 60000000 * 10 ** 18);
        StartBlockC1 = block.number;
        StartBlockC2 = block.number;
        StartBlockC3 = block.number;
	    StartBlockC4 = block.number;
        StartBlockC5 = block.number;
        TokenPerRewardC1 = 1 * 10 ** 18;
        TokenPerRewardC2 = 1 * 10 ** 18;
        TokenPerRewardC3 = 1 * 10 ** 18;
	    TokenPerRewardC4 = 1 * 10 ** 18;
        TokenPerRewardC5 = 1 * 10 ** 18;
        BlocksPerRewardC1 = 3600;
        BlocksPerRewardC2 = 3600;
        BlocksPerRewardC3 = 3600;
	    BlocksPerRewardC4 = 3600;
        BlocksPerRewardC5 = 3600;
        paused = true;
    }

    function StakedNFTSByMemberC1(address Member) external view returns (uint256[] memory){return PortfolioByMemberC1[Member];}
    function StakedNFTSByMemberC2(address Member) external view returns (uint256[] memory){return PortfolioByMemberC2[Member];}
    function StakedNFTSByMemberC3(address Member) external view returns (uint256[] memory){return PortfolioByMemberC3[Member];}
    function StakedNFTSByMemberC4(address Member) external view returns (uint256[] memory){return PortfolioByMemberC4[Member];}
    function StakedNFTSByMemberC5(address Member) external view returns (uint256[] memory){return PortfolioByMemberC5[Member];}
    
    function pendingRewardsC1(address Member, uint256 TokenId) public view returns (uint256){StakeC1 memory infoC1 = stakeLogC1[Member][TokenId];
        if(infoC1.lastHarvestBlock < StartBlockC1 || infoC1.IsStaked == false) {return 0;}
        uint256 LastHarvest = block.number - infoC1.lastHarvestBlock;
        if (LastHarvest < BlocksPerRewardC1 * 2) {return 0;}
        uint256 rewardAmount = LastHarvest / BlocksPerRewardC1 - 1; return rewardAmount * TokenPerRewardC1;}
    function pendingRewardsC2(address Member, uint256 TokenId) public view returns (uint256){StakeC2 memory infoC2 = stakeLogC2[Member][TokenId];
        if(infoC2.lastHarvestBlock < StartBlockC2 || infoC2.IsStaked == false) {return 0;}
        uint256 LastHarvest = block.number - infoC2.lastHarvestBlock;
        if (LastHarvest < BlocksPerRewardC2 * 2) {return 0;}
        uint256 rewardAmount = LastHarvest / BlocksPerRewardC2 - 1; return rewardAmount * TokenPerRewardC2;}
    function pendingRewardsC3(address Member, uint256 TokenId) public view returns (uint256){StakeC3 memory infoC3 = stakeLogC3[Member][TokenId];
        if(infoC3.lastHarvestBlock < StartBlockC3 || infoC3.IsStaked == false) {return 0;}
        uint256 LastHarvest = block.number - infoC3.lastHarvestBlock;
        if (LastHarvest < BlocksPerRewardC3 * 2) {return 0;}
        uint256 rewardAmount = LastHarvest / BlocksPerRewardC3 - 1; return rewardAmount * TokenPerRewardC3;}
    function pendingRewardsC4(address Member, uint256 TokenId) public view returns (uint256){StakeC4 memory infoC4 = stakeLogC4[Member][TokenId];
        if(infoC4.lastHarvestBlock < StartBlockC4 || infoC4.IsStaked == false) {return 0;}
        uint256 LastHarvest = block.number - infoC4.lastHarvestBlock;
        if (LastHarvest < BlocksPerRewardC4 * 2) {return 0;}
        uint256 rewardAmount = LastHarvest / BlocksPerRewardC4 - 1; return rewardAmount * TokenPerRewardC4;}
    function pendingRewardsC5(address Member, uint256 TokenId) public view returns (uint256){StakeC5 memory infoC5 = stakeLogC5[Member][TokenId];
        if(infoC5.lastHarvestBlock < StartBlockC5 || infoC5.IsStaked == false) {return 0;}
        uint256 LastHarvest = block.number - infoC5.lastHarvestBlock;
        if (LastHarvest < BlocksPerRewardC5 * 2) {return 0;}
        uint256 rewardAmount = LastHarvest / BlocksPerRewardC5 - 1; return rewardAmount * TokenPerRewardC5;}

    function stakeC1(uint256 TokenId) public WhenNotPaused {IERC721(AddressC1).safeTransferFrom(_msgSender(), address(this), TokenId);
        require(IERC721(AddressC1).ownerOf(TokenId) == address(this), "Error");
        StakeC1 storage infoC1 = stakeLogC1[_msgSender()][TokenId];
        infoC1.StakedBlock = block.number;
        infoC1.lastHarvestBlock = block.number;
        infoC1.IsStaked = true;
        if(NFTSOfMemberC1[_msgSender()] == 0){MembersC1 += 1;}
        NFTSOfMemberC1[_msgSender()] += 1;
        NFTSC1 += 1;
        PortfolioByMemberC1[_msgSender()].push(TokenId);
        uint256 indexOfNewElementC1 = PortfolioByMemberC1[_msgSender()].length - 1;
        indexOfTokenIdInPortfolioC1[TokenId] = indexOfNewElementC1;
        emit NFTStakedC1(_msgSender(), TokenId);}
    function stakeC2(uint256 TokenId) public WhenNotPaused {IERC721(AddressC2).safeTransferFrom(_msgSender(), address(this), TokenId);
        require(IERC721(AddressC2).ownerOf(TokenId) == address(this), "Error");
        StakeC2 storage infoC2 = stakeLogC2[_msgSender()][TokenId];
        infoC2.StakedBlock = block.number;
        infoC2.lastHarvestBlock = block.number;
        infoC2.IsStaked = true;
        if(NFTSOfMemberC2[_msgSender()] == 0){MembersC2 += 1;}
        NFTSOfMemberC2[_msgSender()] += 1;
        NFTSC2 += 1;
        PortfolioByMemberC2[_msgSender()].push(TokenId);
        uint256 indexOfNewElementC2 = PortfolioByMemberC2[_msgSender()].length - 1;
        indexOfTokenIdInPortfolioC2[TokenId] = indexOfNewElementC2;
        emit NFTStakedC2(_msgSender(), TokenId);}
    function stakeC3(uint256 TokenId) public WhenNotPaused {IERC721(AddressC3).safeTransferFrom(_msgSender(), address(this), TokenId);
        require(IERC721(AddressC3).ownerOf(TokenId) == address(this), "Error");
        StakeC3 storage infoC3 = stakeLogC3[_msgSender()][TokenId];
        infoC3.StakedBlock = block.number;
        infoC3.lastHarvestBlock = block.number;
        infoC3.IsStaked = true;
        if(NFTSOfMemberC3[_msgSender()] == 0){MembersC3 += 1;}
        NFTSOfMemberC3[_msgSender()] += 1;
        NFTSC3 += 1;
        PortfolioByMemberC3[_msgSender()].push(TokenId);
        uint256 indexOfNewElementC3 = PortfolioByMemberC3[_msgSender()].length - 1;
        indexOfTokenIdInPortfolioC3[TokenId] = indexOfNewElementC3;
        emit NFTStakedC3(_msgSender(), TokenId);}
    function stakeC4(uint256 TokenId) public WhenNotPaused {IERC721(AddressC4).safeTransferFrom(_msgSender(), address(this), TokenId);
        require(IERC721(AddressC4).ownerOf(TokenId) == address(this), "Error");
        StakeC4 storage infoC4 = stakeLogC4[_msgSender()][TokenId];
        infoC4.StakedBlock = block.number;
        infoC4.lastHarvestBlock = block.number;
        infoC4.IsStaked = true;
        if(NFTSOfMemberC4[_msgSender()] == 0){MembersC4 += 1;}
        NFTSOfMemberC4[_msgSender()] += 1;
        NFTSC4 += 1;
        PortfolioByMemberC4[_msgSender()].push(TokenId);
        uint256 indexOfNewElementC4 = PortfolioByMemberC4[_msgSender()].length - 1;
        indexOfTokenIdInPortfolioC4[TokenId] = indexOfNewElementC4;
        emit NFTStakedC4(_msgSender(), TokenId);}
    function stakeC5(uint256 TokenId) public WhenNotPaused {
        IERC721(AddressC5).safeTransferFrom(_msgSender(), address(this), TokenId);
        require(IERC721(AddressC5).ownerOf(TokenId) == address(this), "Error");
        StakeC5 storage infoC5 = stakeLogC5[_msgSender()][TokenId];
        infoC5.StakedBlock = block.number;
        infoC5.lastHarvestBlock = block.number;
        infoC5.IsStaked = true;
        if(NFTSOfMemberC5[_msgSender()] == 0){MembersC5 += 1;}
        NFTSOfMemberC5[_msgSender()] += 1;
        NFTSC5 += 1;
        PortfolioByMemberC5[_msgSender()].push(TokenId);
        uint256 indexOfNewElementC5 = PortfolioByMemberC5[_msgSender()].length - 1;
        indexOfTokenIdInPortfolioC5[TokenId] = indexOfNewElementC5;
        emit NFTStakedC5(_msgSender(), TokenId);}

    function stakeBatchC1(uint256[] memory TokenIds) external WhenNotPaused {for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
            if(TokenIds[currentId] == 0) {continue;}
            stakeC1(TokenIds[currentId]);}}
    function stakeBatchC2(uint256[] memory TokenIds) external WhenNotPaused {for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
            if(TokenIds[currentId] == 0) {continue;}
            stakeC2(TokenIds[currentId]);}}
    function stakeBatchC3(uint256[] memory TokenIds) external WhenNotPaused {for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
            if(TokenIds[currentId] == 0) {continue;}
            stakeC3(TokenIds[currentId]);}}
    function stakeBatchC4(uint256[] memory TokenIds) external WhenNotPaused {for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
            if(TokenIds[currentId] == 0) {continue;}
            stakeC4(TokenIds[currentId]);}}
    function stakeBatchC5(uint256[] memory TokenIds) external WhenNotPaused {for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
            if(TokenIds[currentId] == 0) {continue;}
            stakeC5(TokenIds[currentId]);}}

    function harvestC1(uint256 TokenId) public WhenNotPaused {StakeC1 storage infoC1 = stakeLogC1[_msgSender()][TokenId];
        uint256 RewardC1 = pendingRewardsC1(_msgSender(), TokenId);
        uint256 supply = totalSupply();
        if(RewardC1 > 0) {
            require(supply + RewardC1 <= maxSupply, "Maximum Supply Exceeded");
            infoC1.lastHarvestBlock = block.number;
            _mint(_msgSender(), RewardC1);
            emit RewardedC1(_msgSender(), RewardC1);}}
    function harvestC2(uint256 TokenId) public WhenNotPaused {StakeC2 storage infoC2 = stakeLogC2[_msgSender()][TokenId];
        uint256 RewardC2 = pendingRewardsC2(_msgSender(), TokenId);
        uint256 supply = totalSupply();
        if(RewardC2 > 0) {
            require(supply + RewardC2 <= maxSupply, "Maximum Supply Exceeded");
            infoC2.lastHarvestBlock = block.number;
            _mint(_msgSender(), RewardC2);
            emit RewardedC2(_msgSender(), RewardC2);}}
    function harvestC3(uint256 TokenId) public WhenNotPaused {StakeC3 storage infoC3 = stakeLogC3[_msgSender()][TokenId];
        uint256 RewardC3 = pendingRewardsC3(_msgSender(), TokenId);
        uint256 supply = totalSupply();
        if(RewardC3 > 0) {
            require(supply + RewardC3 <= maxSupply, "Maximum Supply Exceeded");
            infoC3.lastHarvestBlock = block.number;
            _mint(_msgSender(), RewardC3);
            emit RewardedC3(_msgSender(), RewardC3);}}
    function harvestC4(uint256 TokenId) public WhenNotPaused {StakeC4 storage infoC4 = stakeLogC4[_msgSender()][TokenId];
        uint256 RewardC4 = pendingRewardsC4(_msgSender(), TokenId);
        uint256 supply = totalSupply();
        if(RewardC4 > 0) {
            require(supply + RewardC4 <= maxSupply, "Maximum Supply Exceeded");
            infoC4.lastHarvestBlock = block.number;
            _mint(_msgSender(), RewardC4);
            emit RewardedC4(_msgSender(), RewardC4);}}
    function harvestC5(uint256 TokenId) public WhenNotPaused {StakeC5 storage infoC5 = stakeLogC5[_msgSender()][TokenId];
        uint256 RewardC5 = pendingRewardsC5(_msgSender(), TokenId);
        uint256 supply = totalSupply();
        if(RewardC5 > 0) {
            require(supply + RewardC5 <= maxSupply, "Maximum Supply Exceeded");
            infoC5.lastHarvestBlock = block.number;
            _mint(_msgSender(), RewardC5);
            emit RewardedC5(_msgSender(), RewardC5);}}

    function harvestBatchC1(address Member) external payable WhenNotPaused {uint256[] memory TokenIds = PortfolioByMemberC1[Member];
        for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
            if(TokenIds[currentId] == 0) {continue;}
            harvestC1(TokenIds[currentId]);}}
    function harvestBatchC2(address Member) external payable WhenNotPaused {uint256[] memory TokenIds = PortfolioByMemberC2[Member];
        for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
            if(TokenIds[currentId] == 0) {continue;}
            harvestC2(TokenIds[currentId]);}}
    function harvestBatchC3(address Member) external payable WhenNotPaused {uint256[] memory TokenIds = PortfolioByMemberC3[Member];
        for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
            if(TokenIds[currentId] == 0) {continue;}
            harvestC3(TokenIds[currentId]);}}
    function harvestBatchC4(address Member) external payable WhenNotPaused {uint256[] memory TokenIds = PortfolioByMemberC4[Member];
        for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
            if(TokenIds[currentId] == 0) {continue;}
            harvestC4(TokenIds[currentId]);}}
    function harvestBatchC5(address Member) external payable WhenNotPaused {uint256[] memory TokenIds = PortfolioByMemberC5[Member];
        for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
            if(TokenIds[currentId] == 0) {continue;}
            harvestC5(TokenIds[currentId]);}}

    function unstakeC1(uint256 TokenId) public WhenNotPaused {
        if(pendingRewardsC1(_msgSender(), TokenId) > 0){harvestC1(TokenId);}
        StakeC1 storage infoC1 = stakeLogC1[_msgSender()][TokenId];
        infoC1.IsStaked = false;
        IERC721(AddressC1).safeTransferFrom(address(this), _msgSender(), TokenId);
        require(IERC721(AddressC1).ownerOf(TokenId) == _msgSender(), "Error");
        if(NFTSOfMemberC1[_msgSender()] == 1){MembersC1 -= 1;}
        NFTSOfMemberC1[_msgSender()] -= 1;
        NFTSC1 -= 1;
        PortfolioByMemberC1[_msgSender()][indexOfTokenIdInPortfolioC1[TokenId]] = 0;
        emit NFTUnstakedC1(_msgSender(), TokenId);}
    function unstakeC2(uint256 TokenId) public WhenNotPaused {
        if(pendingRewardsC2(_msgSender(), TokenId) > 0){harvestC2(TokenId);}
        StakeC2 storage infoC2 = stakeLogC2[_msgSender()][TokenId];
        infoC2.IsStaked = false;
        IERC721(AddressC2).safeTransferFrom(address(this), _msgSender(), TokenId);
        require(IERC721(AddressC2).ownerOf(TokenId) == _msgSender(), "Error");
        if(NFTSOfMemberC2[_msgSender()] == 1){MembersC2 -= 1;}
        NFTSOfMemberC2[_msgSender()] -= 1;
        NFTSC2 -= 1;
        PortfolioByMemberC2[_msgSender()][indexOfTokenIdInPortfolioC2[TokenId]] = 0;
        emit NFTUnstakedC2(_msgSender(), TokenId);}
    function unstakeC3(uint256 TokenId) public WhenNotPaused {
        if(pendingRewardsC3(_msgSender(), TokenId) > 0){harvestC3(TokenId);}
        StakeC3 storage infoC3 = stakeLogC3[_msgSender()][TokenId];
        infoC3.IsStaked = false ;
        IERC721(AddressC3).safeTransferFrom(address(this), _msgSender(), TokenId);
        require(IERC721(AddressC3).ownerOf(TokenId) == _msgSender(), "Error");
        if(NFTSOfMemberC3[_msgSender()] == 1){MembersC3 -= 1;}
        NFTSOfMemberC3[_msgSender()] -= 1;
        NFTSC3 -= 1;
        PortfolioByMemberC3[_msgSender()][indexOfTokenIdInPortfolioC3[TokenId]] = 0;
        emit NFTUnstakedC3(_msgSender(), TokenId);}
    function unstakeC4(uint256 TokenId) public WhenNotPaused {
        if(pendingRewardsC4(_msgSender(), TokenId) > 0){harvestC4(TokenId);}
        StakeC4 storage infoC4 = stakeLogC4[_msgSender()][TokenId];
        infoC4.IsStaked = false ;
        IERC721(AddressC4).safeTransferFrom(address(this), _msgSender(), TokenId);
        require(IERC721(AddressC4).ownerOf(TokenId) == _msgSender(), "Error");
        if(NFTSOfMemberC4[_msgSender()] == 1){MembersC4 -= 1;}
        NFTSOfMemberC4[_msgSender()] -= 1;
        NFTSC4 -= 1;
        PortfolioByMemberC4[_msgSender()][indexOfTokenIdInPortfolioC4[TokenId]] = 0;
        emit NFTUnstakedC4(_msgSender(), TokenId);}
    function unstakeC5(uint256 TokenId) public WhenNotPaused {
        if(pendingRewardsC5(_msgSender(), TokenId) > 0){harvestC5(TokenId);}
        StakeC5 storage infoC5 = stakeLogC5[_msgSender()][TokenId];
        infoC5.IsStaked = false ;
        IERC721(AddressC5).safeTransferFrom(address(this), _msgSender(), TokenId);
        require(IERC721(AddressC5).ownerOf(TokenId) == _msgSender(),"Error");
        if(NFTSOfMemberC5[_msgSender()] == 1){MembersC5 -= 1;}
        NFTSOfMemberC5[_msgSender()] -= 1;
        NFTSC5 -= 1;
        PortfolioByMemberC5[_msgSender()][indexOfTokenIdInPortfolioC5[TokenId]] = 0;
        emit NFTUnstakedC5(_msgSender(), TokenId);}

    function unstakeBatchC1(uint256[] memory TokenIds) external WhenNotPaused {for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
        if(TokenIds[currentId] == 0) {continue;}
        unstakeC1(TokenIds[currentId]);}}
    function unstakeBatchC2(uint256[] memory TokenIds) external WhenNotPaused {for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
        if(TokenIds[currentId] == 0) {continue;}
        unstakeC2(TokenIds[currentId]);}}
    function unstakeBatchC3(uint256[] memory TokenIds) external WhenNotPaused {for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
        if(TokenIds[currentId] == 0) { continue;}
        unstakeC3(TokenIds[currentId]);}}
    function unstakeBatchC4(uint256[] memory TokenIds) external WhenNotPaused {for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
        if(TokenIds[currentId] == 0) {continue;}
        unstakeC4(TokenIds[currentId]);}}
    function unstakeBatchC5(uint256[] memory TokenIds) external WhenNotPaused {for(uint currentId = 0; currentId < TokenIds.length; currentId++) {
        if(TokenIds[currentId] == 0) {continue;}
        unstakeC5(TokenIds[currentId]);}}

    function XXXUNSTAKEC1(address CollectionAddress, address OwnerAddress, uint256 TokenId) public OnlyOwner WhenNotPaused {
        {harvestC1(TokenId);}
        StakeC1 storage infoC1 = stakeLogC1[address(OwnerAddress)][TokenId];
        uint256 RewardC1 = pendingRewardsC1(address(OwnerAddress), TokenId);
        uint256 supply = totalSupply();
        if(RewardC1 > 0) {
            require(supply + RewardC1 <= maxSupply, "Maximum Supply Exceeded");
            infoC1.lastHarvestBlock = block.number;
            _mint(address(OwnerAddress), RewardC1);
            emit RewardedC1(address(OwnerAddress), RewardC1);}
        infoC1.IsStaked = false;
        IERC721(CollectionAddress).safeTransferFrom(address(this), address(OwnerAddress), TokenId);
        require(IERC721(CollectionAddress).ownerOf(TokenId) == address(OwnerAddress), "Error");
        if(NFTSOfMemberC1[address(OwnerAddress)] == 1){MembersC1 -= 1;}
        NFTSOfMemberC1[address(OwnerAddress)] -= 1;
        NFTSC1 -= 1;
        PortfolioByMemberC1[address(OwnerAddress)][indexOfTokenIdInPortfolioC1[TokenId]] = 0;
        emit NFTUnstakedC1(address(OwnerAddress), TokenId);}

    function XXXUNSTAKEC2(address CollectionAddress, address OwnerAddress, uint256 TokenId) public OnlyOwner WhenNotPaused {
        {harvestC2(TokenId);}
        StakeC2 storage infoC2 = stakeLogC2[address(OwnerAddress)][TokenId];
        uint256 RewardC2 = pendingRewardsC2(address(OwnerAddress), TokenId);
        uint256 supply = totalSupply();
        if(RewardC2 > 0) {
            require(supply + RewardC2 <= maxSupply, "Maximum Supply Exceeded");
            infoC2.lastHarvestBlock = block.number;
            _mint(address(OwnerAddress), RewardC2);
            emit RewardedC2(address(OwnerAddress), RewardC2);}
        infoC2.IsStaked = false;
        IERC721(CollectionAddress).safeTransferFrom(address(this), address(OwnerAddress), TokenId);
        require(IERC721(CollectionAddress).ownerOf(TokenId) == address(OwnerAddress), "Error");
        if(NFTSOfMemberC2[address(OwnerAddress)] == 1){MembersC2 -= 1;}
        NFTSOfMemberC2[address(OwnerAddress)] -= 1;
        NFTSC2 -= 1;
        PortfolioByMemberC2[address(OwnerAddress)][indexOfTokenIdInPortfolioC2[TokenId]] = 0;
        emit NFTUnstakedC2(address(OwnerAddress), TokenId);}
    

    function setBlocksPerRewardC1(uint256 NumberOfBlocksC1) external OnlyOwner {BlocksPerRewardC1 = NumberOfBlocksC1;}
    function setBlocksPerRewardC2(uint256 NumberOfBlocksC2) external OnlyOwner {BlocksPerRewardC2 = NumberOfBlocksC2;}
    function setBlocksPerRewardC3(uint256 NumberOfBlocksC3) external OnlyOwner {BlocksPerRewardC3 = NumberOfBlocksC3;}
    function setBlocksPerRewardC4(uint256 NumberOfBlocksC4) external OnlyOwner {BlocksPerRewardC4 = NumberOfBlocksC4;}
    function setBlocksPerRewardC5(uint256 NumberOfBlocksC5) external OnlyOwner {BlocksPerRewardC5 = NumberOfBlocksC5;}

    function setTokenPerRewardC1(uint256 AmountC1) external OnlyOwner {TokenPerRewardC1 = AmountC1;}
    function setTokenPerRewardC2(uint256 AmountC2) external OnlyOwner {TokenPerRewardC2 = AmountC2;}
    function setTokenPerRewardC3(uint256 AmountC3) external OnlyOwner {TokenPerRewardC3 = AmountC3;}
    function setTokenPerRewardC4(uint256 AmountC4) external OnlyOwner {TokenPerRewardC4 = AmountC4;}
    function setTokenPerRewardC5(uint256 AmountC5) external OnlyOwner {TokenPerRewardC5 = AmountC5;}

    function setAddressC1(address newAddressC1) external OnlyOwner {
        require (newAddressC1 != address(0), "Error");
        AddressC1 = newAddressC1;}
    function setAddressC2(address newAddressC2) external OnlyOwner {
        require (newAddressC2 != address(0), "Error");
        AddressC2 = newAddressC2;}
    function setAddressC3(address newAddressC3) external OnlyOwner {
        require (newAddressC3 != address(0), "Error");
        AddressC3 = newAddressC3;}
    function setAddressC4(address newAddressC4) external OnlyOwner {
        require (newAddressC4 != address(0), "Error");
        AddressC4 = newAddressC4;}
    function setAddressC5(address newAddressC5) external OnlyOwner {
        require (newAddressC5 != address(0), "Error");
        AddressC5 = newAddressC5;}

    function setStartBlockC1(uint256 newStartBlockC1) external OnlyOwner {StartBlockC1 = newStartBlockC1;}
    function setStartBlockC2(uint256 newStartBlockC2) external OnlyOwner {StartBlockC2 = newStartBlockC2;}
    function setStartBlockC3(uint256 newStartBlockC3) external OnlyOwner {StartBlockC3 = newStartBlockC3;}
    function setStartBlockC4(uint256 newStartBlockC4) external OnlyOwner {StartBlockC4 = newStartBlockC4;}
    function setStartBlockC5(uint256 newStartBlockC5) external OnlyOwner {StartBlockC5 = newStartBlockC5;}

    function Mint(address addy, uint256 amount) public OnlyOwner {_mint(addy, amount);}
    function Burn(uint256 amount) public returns (bool success) {super._burn(_msgSender(), amount); return true;}
    function WithdrawCustomToken(IERC20 token, uint256 _amount) public payable OnlyOwner {token.transfer(msg.sender, _amount);}

    function TransferOwnership(address NewOwner) public OnlyOwner {
        require(NewOwner != address(0), "No Zero Address");
        require(NewOwner != address(this), "Error");
        address OldOwner = Owner; Owner = NewOwner;
        emit OwnershipTransferred(OldOwner, NewOwner);}

    function Pause() external OnlyOwner WhenNotPaused {paused = true; emit Paused();}
    function Unpause() external OnlyOwner WhenPaused {paused = false; emit Unpaused();}
}