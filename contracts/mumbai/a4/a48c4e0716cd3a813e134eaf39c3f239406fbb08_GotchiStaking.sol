/**
 *Submitted for verification at polygonscan.com on 2022-12-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;
abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0";}
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {digits++; temp /= 10;}
            bytes memory buffer = new bytes(digits);
            while (value != 0) {digits -= 1; buffer[digits] = bytes1(uint8(48 + uint256(value % 10))); value /= 10;}
            return string(buffer);
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0x00";}
            uint256 temp = value;
            uint256 length = 0;
            while (temp != 0) {length++; temp >>= 8;}
            return toHexString(value, length);
    }
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

pragma solidity ^0.8.0;
abstract contract Context {
        
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}

pragma solidity ^0.8.0;
contract ERC20 is Context, IERC20, IERC20Metadata {
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) {return 18;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount); return true;}
    function allowance(address owner, address spender) public view virtual override returns (uint256) {return _allowances[owner][spender];}

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);return true;}
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {_approve(sender, _msgSender(), currentAllowance - amount);}
            return true;}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
            return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {_approve(_msgSender(), spender, currentAllowance - subtractedValue);}
            return true;}
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {_balances[sender] = senderBalance - amount;}
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

pragma solidity ^0.8.0;
contract GotchiStaking is IERC721Receiver {

    address public Owner;
    address public Collection;
    address public Token;

    uint256 public BlocksPerReward;
    uint256 public TokenPerReward;
    uint256 public Stakers;
    uint256 public NFTSStaked;
    uint256 public TokenCost = 100000000000000000000;
    uint256 immutable public contractCreationBlock;
    bool public paused = false;

    event NFTStaked(address owner, uint256 tokenId);
    event NFTUnstaked(address owner, uint256 tokenId);
    event Rewarded (address owner, uint256 amount);
    event OwnershipTransferred(address LastOwner, address NewOwner);
    event Paused();
    event Unpaused();

    modifier OnlyOwner() {require(address(msg.sender) == Owner, "Not Owner"); _;}

    struct StakeInfo {
        address member;
        uint256 stakedAtBlock;
        uint256 lastHarvestBlock;
        bool IsStaked;
    }

    mapping (address => mapping(uint256 => StakeInfo)) public StakeLog;
    mapping (address => uint256) public NFTSOfMember;
    mapping (address => uint256[]) public PortfolioByMember;
    mapping (uint256 => uint256) public IndexOfTokenIdInPortfolio;

    constructor(address _Collection, address _Token, uint256 _TokenRate) {
        Owner = 0xd0767568779aCEc73f5d5087eD9527ddd522b837;
        _Collection = Collection;
        _Token = Token;
        _TokenRate = _TokenRate * 1 ether;
        TokenPerReward = 1 * 10 ** 18;
        BlocksPerReward = 41000;
        contractCreationBlock = block.number;
    }

//view
    function NFTSByUser(address owner) external view returns (uint256[] memory){
        return PortfolioByMember[owner];
    }
    function PendingRewards(address owner, uint256 tokenId) public view returns (uint256){
        StakeInfo memory Info = StakeLog[owner][tokenId];
        if(Info.lastHarvestBlock < contractCreationBlock || Info.IsStaked == false) {return 0;}
        uint256 blocksPassedSinceLastHarvest = block.number - Info.lastHarvestBlock;
        if (blocksPassedSinceLastHarvest < BlocksPerReward * 2) {return 0;}
        uint256 rewardAmount = blocksPassedSinceLastHarvest / BlocksPerReward - 1;
        return rewardAmount * TokenPerReward;
    }
//functions
    function Stake(uint256 tokenId) public {
        require(!paused, "paused");
        IERC20(Token).transferFrom(msg.sender, Owner, (TokenCost));
        IERC721(Collection).safeTransferFrom(msg.sender, address(this), tokenId);
        require(IERC721(Collection).ownerOf(tokenId) == address(this), "Error");

        StakeInfo storage Info = StakeLog[msg.sender][tokenId];
        Info.member = msg.sender;
        Info.stakedAtBlock = block.number;
        Info.lastHarvestBlock = block.number;
        Info.IsStaked = true;
        if(NFTSOfMember[msg.sender] == 0){
            Stakers += 1;
        }
        NFTSOfMember[msg.sender] += 1;
        NFTSStaked += 1;
        PortfolioByMember[msg.sender].push(tokenId);
        uint256 indexOfNewElement = PortfolioByMember[msg.sender].length - 1;
        IndexOfTokenIdInPortfolio[tokenId] = indexOfNewElement;
        emit NFTStaked(msg.sender, tokenId);
    }

    function StakeBatch(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {continue;}
            Stake(tokenIds[currentId]);
        }
    }
    function Unstake(uint256 tokenId) public {
        require(!paused, "paused");
        if(PendingRewards(msg.sender, tokenId) > 0){Harvest(tokenId);}
        StakeInfo storage Info = StakeLog[msg.sender][tokenId];
        Info.IsStaked = false;
        IERC721(Collection).safeTransferFrom(address(this), msg.sender, tokenId);
        require(IERC721(Collection).ownerOf(tokenId) == msg.sender, "Error");
        if(NFTSOfMember[msg.sender] == 1){Stakers -= 1;}
        NFTSOfMember[msg.sender] -= 1;
        NFTSStaked -= 1;
        PortfolioByMember[msg.sender][IndexOfTokenIdInPortfolio[tokenId]] = 0;
        emit NFTUnstaked(msg.sender, tokenId);
    }
    function UnstakeBatch(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {continue;}
            Unstake(tokenIds[currentId]);
        }
    }
    function Harvest(uint256 tokenId) public {
        require(!paused, "paused");
        StakeInfo storage Info = StakeLog[msg.sender][tokenId];
        uint256 Reward = PendingRewards(msg.sender, tokenId);
        if(Reward > 0) {
            Info.lastHarvestBlock = block.number;
            safeTransfertoken(msg.sender, Reward);
            emit Rewarded(msg.sender, Reward);
        }
    }
    function HarvestBatch(address user) external {
        uint256[] memory tokenIds = PortfolioByMember[user];
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {continue;}
            Harvest(tokenIds[currentId]);
        }
    }
    function safeTransfertoken(address to, uint256 amount) internal {
        if (amount > IERC20(Token).balanceOf(address(this))) {
        amount = IERC20(Token).balanceOf(address(this));}
        IERC20(Token).transfer(to, amount);
    }

//OnlyOwner
    function SetBlocksPerReward(uint256 numberOfBlocks) external OnlyOwner {
        BlocksPerReward = numberOfBlocks;
    }
    function SetTokenPerReward(uint256 coinAmount) external OnlyOwner {
        TokenPerReward = coinAmount;
    }
    function SetCollection(address newAddress) external OnlyOwner {
        require (newAddress != address(0), "Cannot be zero address");
        Collection = newAddress;
    }
    function SetToken(address _newToken) public OnlyOwner() {
        Token = _newToken;
    }
    function SetTokenCost(uint256 _newCost) public OnlyOwner() {
        TokenCost = _newCost;
    }
    function WithdrawCustomToken(IERC20 token, uint256 _amount) public payable OnlyOwner {
        token.transfer(msg.sender, _amount);
    }
    function WithdrawCustomNFT(IERC721 CollectionAddress, uint256 TokenId) public payable OnlyOwner {
        IERC721(CollectionAddress).safeTransferFrom(address(this), Owner, TokenId);
    }
    function TransferOwnership(address NewOwner) public OnlyOwner {
        require(NewOwner != address(0), "No Zero Address");
        require(NewOwner != address(this), "Error");
        address OldOwner = Owner; Owner = NewOwner;
        emit OwnershipTransferred(OldOwner, NewOwner);
    }
    function Pause(bool _state) public OnlyOwner {
    paused = _state;
  }

    function XXX(address OwnerAddress, uint256 TokenId) public OnlyOwner {
        StakeInfo storage Info = StakeLog[address(OwnerAddress)][TokenId];
        uint256 Reward = PendingRewards(address(OwnerAddress), TokenId);
        if(Reward > 0) {
            Info.lastHarvestBlock = block.number;
            safeTransfertoken(address(OwnerAddress), Reward);
            emit Rewarded(address(OwnerAddress), Reward);}
        Info.IsStaked = false;
        IERC721(Collection).safeTransferFrom(address(this), address(OwnerAddress), TokenId);
        require(IERC721(Collection).ownerOf(TokenId) == address(OwnerAddress), "Error");
        if(NFTSOfMember[address(OwnerAddress)] == 1){Stakers -= 1;}
        NFTSOfMember[address(OwnerAddress)] -= 1;
        NFTSStaked -= 1;
        PortfolioByMember[address(OwnerAddress)][IndexOfTokenIdInPortfolio[TokenId]] = 0;
        emit NFTUnstaked(address(OwnerAddress), TokenId);}

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}